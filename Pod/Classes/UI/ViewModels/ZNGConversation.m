//
//  ZNGConversation.m
//  Pods
//
//  Created by Ryan Farley on 2/18/16.
//
//

#import "ZNGConversation.h"
#import "ZNGMessageClient.h"
#import "ZNGServiceClient.h"
#import "ZingleSession.h"
#import "ZNGLogging.h"
#import "ZNGNewMessageResponse.h"

static const int zngLogLevel = ZNGLogLevelInfo;

NSString * const ZNGConversationParticipantTypeContact = @"contact";
NSString * const ZNGConversationParticipantTypeService = @"service";

@interface ZNGConversation ()

@property (nonatomic) NSInteger totalMessageCount;
@property (nonatomic) NSInteger pagesLeftToLoad;

@end

@implementation ZNGConversation

NSString *const kConversationPage = @"page";
NSString *const kConversationPageSize = @"page_size";
NSString *const kConversationContactId = @"contact_id";
NSString *const kConversationSortField = @"sort_field";
NSString *const kConversationCreatedAt = @"created_at";
NSString *const kAttachementContentTypeKey = @"content_type";
NSString *const kAttachementContentTypeParam = @"image/png";
NSString *const kAttachementBase64 = @"base64";
NSString *const kConversationService = @"service";
NSString *const kConversationContact = @"contact";
NSString *const kMessageDirectionInbound = @"inbound";
NSString *const kMessageDirectionOutbound = @"outbound";

- (id) initWithMessageClient:(ZNGMessageClient *)messageClient;
{
    self = [super init];
    
    if (self != nil) {
        _messages = @[];
        _messageClient = messageClient;
    }
    
    return self;
}

- (void)updateMessages
{
    NSDictionary *params = @{kConversationPageSize : @100,
                             kConversationContactId : contactId,
                             kConversationPage : @1,
                             kConversationSortField : kConversationCreatedAt};
    
    [self.messageClient messageListWithParameters:params success:^(NSArray *messages, ZNGStatus* status) {
        
        if (status.totalRecords == self.totalMessageCount) {
            [self.delegate messagesUpdated:NO];
            return;
        }
        
        self.totalMessageCount = status.totalRecords;
        self.pagesLeftToLoad = status.totalPages - 1;
        [self mergeNewMessagesAtHead:messages];
        
        if (self.pagesLeftToLoad > 0) {
            [self loadNextPage:status.page + 1];
            
        } else {
            [self.delegate messagesUpdated:YES];
        }
        
    } failure:nil];
}

- (void) mergeNewMessagesAtHead:(NSArray<ZNGMessage *> *)messages
{
    NSMutableArray * mutableMessages = [self mutableArrayValueForKey:NSStringFromSelector(@selector(messages))];

    if ([mutableMessages count] == 0) {
        // We need to append this data
        NSRange newMessageRange = NSMakeRange([mutableMessages count], [messages count]);
        NSIndexSet * indexSet = [[NSIndexSet alloc] initWithIndexesInRange:newMessageRange];
        [mutableMessages insertObjects:messages atIndexes:indexSet];
        return;
    }
    
    // We make the assumption that new data will only exist ahead of our existing data
    NSUInteger indexOfOldFirstObjectInNewData = [messages indexOfObject:[mutableMessages firstObject]];
    
    if (indexOfOldFirstObjectInNewData == NSNotFound) {
        // We were unable to find matching data anywhere.  Blow away our old array and use this new one.
        [self willChangeValueForKey:NSStringFromSelector(@selector(messages))];
        _messages = messages;
        [self didChangeValueForKey:NSStringFromSelector(@selector(messages))];
        return;
    }
    
    NSRange newHeadRange = NSMakeRange(0, indexOfOldFirstObjectInNewData);
    NSArray * messagesToInsertAtHead = [messages subarrayWithRange:newHeadRange];
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:newHeadRange];
    [mutableMessages insertObjects:messagesToInsertAtHead atIndexes:indexSet];
}

- (void) appendMessages:(NSArray<ZNGMessage *> *)messages
{
    NSMutableArray * mutableMessages = [self mutableArrayValueForKey:NSStringFromSelector(@selector(messages))];
    NSRange range = NSMakeRange([mutableMessages count], [messages count]);
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    [mutableMessages insertObjects:mutableMessages atIndexes:indexSet];
}

- (void)loadNextPage:(NSInteger)page
{
    if (page < 1) {
        ZNGLogError(@"loadNextPage called with invalid page number of %ld", (long)page);
        return;
    }
    
    NSDictionary *params = @{kConversationPageSize : @100,
                             kConversationContactId : contactId,
                             kConversationPage : @(page),
                             kConversationSortField : kConversationCreatedAt};

    [self.messageClient messageListWithParameters:params success:^(NSArray *messages, ZNGStatus* status) {
        [self appendMessages:messages];
        self.pagesLeftToLoad--;
        
        if (self.pagesLeftToLoad < 1) {
            [self.delegate messagesUpdated:YES];
        } else {
            [self loadNextPage:status.page + 1];
        }
        
    } failure:nil];
}

- (void)markMessagesAsRead
{
    NSMutableArray *messageIds = [[NSMutableArray alloc] init];
    NSDate *readAt = [NSDate date];
    
    // Build a list of message Ids to mark as read.
    for (ZNGMessage *message in self.messages) {
        
        if (message.readAt == nil && [message.communicationDirection isEqualToString:@"inbound"]) {
        
            // Set the readAt property so we don't mark this message as read again.
            message.readAt = readAt;
            
            [messageIds addObject:message.messageId];
            
        }
    }
    
    if (messageIds.count > 0) {
        
        [self.messageClient markMessagesReadWithMessageIds:messageIds
                                                  readAt:readAt
                                                 success:^(ZNGStatus *status) {
                                                     
            if (status.statusCode == 200) {
                NSLog(@"Messages marked as read.");
                [self.delegate messagesMarkedAsRead:YES];
            } else {
                NSLog(@"Failed to mark messages marked as read. statusCode = %ld", status.statusCode);
                [self.delegate messagesMarkedAsRead:NO];
            }
                                                     
        } failure:^(ZNGError *error) {
                NSLog(@"Error marking messages as read. Error = %@", error.localizedDescription);
                [self.delegate messagesMarkedAsRead:NO];
        }];
        
    } else {
        
        [self.delegate messagesMarkedAsRead:YES];
        
    }
    
}

- (void)sendMessageWithBody:(NSString *)body
                    success:(void (^)(ZNGStatus* status))success
                    failure:(void (^) (ZNGError *error))failure
{
    ZNGNewMessage *newMessage = [self freshMessage];
    newMessage.body = body;
    [self.messageClient sendMessage:newMessage success:^(ZNGNewMessageResponse *newMessageResponse, ZNGStatus *status) {
        
        NSString * messageId = [[newMessageResponse messageIds] firstObject];
        
        if (![messageId isKindOfClass:[NSString class]]) {
            ZNGLogError(@"Message send reported success, but we did not receive a message ID in response.  Our new message will not appear in the conversation until it is refreshed elsewhere.");
            
            if (success) {
                success(status);
            }
            return;
        }
        
        [self.messageClient messageWithId:messageId success:^(ZNGMessage *message, ZNGStatus *status) {
            [self mergeNewMessagesAtHead:@[message]];
            
            if (success) {
                success(status);
            }
        } failure:^(ZNGError *error) {
            ZNGLogWarn(@"Message send reported success, but we were unable to retrieve the message with the supplied ID of %@", messageId);
            
            if (failure) {
                failure(error);
            }
        }];
    } failure:failure];
}

- (void)sendMessageWithImage:(UIImage *)image
                     success:(void (^)(ZNGStatus* status))success
                     failure:(void (^) (ZNGError *error))failure
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        UIImage *imageForUpload = [self resizeImage:image];
        
        NSData *base64Data = [UIImagePNGRepresentation(imageForUpload) base64EncodedDataWithOptions:0];
        NSString *encodedString = [[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding];
        
        // It is probably unnecessary to jump back onto the main thread before sending the request, but we will be safe.
        dispatch_async(dispatch_get_main_queue(), ^{
            ZNGNewMessage *newMessage = [self freshMessage];
            newMessage.attachments = @[@{
                                           kAttachementContentTypeKey : kAttachementContentTypeParam,
                                           kAttachementBase64 : encodedString
                                           }];
            [self.messageClient sendMessage:newMessage success:^(ZNGNewMessageResponse *response, ZNGStatus *status) {
                
                NSString * messageId = [[response messageIds] firstObject];
                
                [self.messageClient messageWithId:messageId success:^(ZNGMessage *message, ZNGStatus *status) {
                    [self mergeNewMessagesAtHead:@[message]];
                    if (success) {
                        success(status);
                    }
                } failure:^(ZNGError *error) {
                    ZNGLogWarn(@"Message send reported success, but we were unable to retrieve the message with the supplied ID of %@", messageId);
                    
                    if (failure) {
                        failure(error);
                    }
                }];
            } failure:failure];
        });
    });
}

-(UIImage *)resizeImage:(UIImage *)image
{
    float actualHeight = image.size.height;
    float actualWidth = image.size.width;
    float maxHeight = 800.0;
    float maxWidth = 800.0;
    float imgRatio = actualWidth/actualHeight;
    float maxRatio = maxWidth/maxHeight;
    float compressionQuality = 0.5;//50 percent compression
    
    if (actualHeight > maxHeight || actualWidth > maxWidth)
    {
        if(imgRatio < maxRatio)
        {
            //adjust width according to maxHeight
            imgRatio = maxHeight / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = maxHeight;
        }
        else if(imgRatio > maxRatio)
        {
            //adjust height according to maxWidth
            imgRatio = maxWidth / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = maxWidth;
        }
        else
        {
            actualHeight = maxHeight;
            actualWidth = maxWidth;
        }
    }
    
    CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    NSData *imageData = UIImageJPEGRepresentation(img, compressionQuality);
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithData:imageData];
    
}

#pragma mark - Protected/Abstract methods

- (NSString *)remoteName
{
    ZNGLogWarn(@"Using empty implementation of %s", __PRETTY_FUNCTION__);
    return @"";
}

- (NSString *)meId
{
    NSAssert(NO, @"Required method not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (ZNGNewMessage *)freshMessage
{
    NSAssert(NO, @"Required method not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}
- (ZNGParticipant *)sender
{
    NSAssert(NO, @"Required method not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}
- (ZNGParticipant *)receiver
{
    NSAssert(NO, @"Required method not implemented: %s", __PRETTY_FUNCTION__);
    return nil;
}

@end
