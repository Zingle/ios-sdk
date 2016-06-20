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

static const int zngLogLevel = ZNGLogLevelInfo;

@interface ZNGConversation ()

@property (nonatomic) NSInteger totalMessageCount;
@property (nonatomic) NSInteger pagesLeftToLoad;

@end

@implementation ZNGConversation
{
    dispatch_queue_t messageMergingQueue;
}

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

- (id) init
{
    self = [super init];
    
    if (self != nil) {
        _messages = @[];
        messageMergingQueue = dispatch_queue_create("com.zingleme.message.conversation.merging", 0);
    }
    
    return self;
}

- (NSString *)contactChannelValue
{
    if (_contactChannelValue == nil) {
        _contactChannelValue = self.contactId;
    }
    return _contactChannelValue;
}

- (NSString *)serviceChannelValue
{
    if (_serviceChannelValue == nil) {
        _serviceChannelValue = self.serviceId;
    }
    return _serviceChannelValue;
}

- (void)updateMessages
{
    NSDictionary *params = @{kConversationPageSize : @100,
                             kConversationContactId : self.contactId,
                             kConversationPage : @1,
                             kConversationSortField : kConversationCreatedAt};
    
    [self.session.messageClient messageListWithParameters:params success:^(NSArray *messages, ZNGStatus* status) {
        
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
                             kConversationContactId : self.contactId,
                             kConversationPage : @(page),
                             kConversationSortField : kConversationCreatedAt};

    [self.session.messageClient messageListWithParameters:params success:^(NSArray *messages, ZNGStatus* status) {
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
        
        [self.session.messageClient markMessagesReadWithMessageIds:messageIds
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
    if (self.channelType == nil) {
        [self.session.serviceClient serviceWithId:self.serviceId success:^(ZNGService *service, ZNGStatus *status) {
            for (ZNGChannelType *channelType in service.channelTypes) {
                
                if ([channelType.typeClass isEqualToString:@"UserDefinedChannel"]) {
                    self.channelType = channelType;
                    ZNGNewMessage *newMessage = [self newMessageToService:self.toService forTypeClass:channelType.typeClass];
                    newMessage.body = body;
                    newMessage.channelTypeIds = @[self.channelType.channelTypeId];
                    [self.session.messageClient sendMessage:newMessage success:^(ZNGMessage *message, ZNGStatus *status) {
                        if (success) {
                            success(status);
                        }
                    } failure:failure];
                }
            }
            if (self.channelType == nil) {
                NSLog(@"Service %@ (id=%@) does not support user defined channels. You must set the channelTypeId.", service.displayName, service.serviceId);
                failure(nil);
            }
        } failure:^(ZNGError *error) {
            NSLog(@"Service ID is required.");
            failure(error);
        }];
    } else {
        ZNGNewMessage *newMessage = [self newMessageToService:self.toService forTypeClass:self.channelType.typeClass];
        newMessage.body = body;
        newMessage.channelTypeIds = @[self.channelType.channelTypeId];
        [self.session.messageClient sendMessage:newMessage success:^(ZNGMessage *message, ZNGStatus *status) {
            if (success) {
                success(status);
            }
        } failure:failure];
    }
}

- (void)sendMessageWithImage:(UIImage *)image
                     success:(void (^)(ZNGStatus* status))success
                     failure:(void (^) (ZNGError *error))failure
{
    UIImage *imageForUpload = [self resizeImage:image];
    
    NSData *base64Data = [UIImagePNGRepresentation(imageForUpload) base64EncodedDataWithOptions:0];
    NSString *encodedString = [[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding];
    
    if (self.channelType == nil) {
        [self.session.serviceClient serviceWithId:self.serviceId success:^(ZNGService *service, ZNGStatus *status) {
            for (ZNGChannelType *channelType in service.channelTypes) {
                
                if ([channelType.typeClass isEqualToString:@"UserDefinedChannel"]) {
                    self.channelType = channelType;
                    ZNGNewMessage *newMessage = [self newMessageToService:self.toService forTypeClass:channelType.typeClass];
                    newMessage.attachments = @[@{
                                                   kAttachementContentTypeKey : kAttachementContentTypeParam,
                                                   kAttachementBase64 : encodedString
                                                   }];
                    newMessage.channelTypeIds = @[self.channelType.channelTypeId];
                    [self.session.messageClient sendMessage:newMessage success:^(ZNGMessage *message, ZNGStatus *status) {
                        if (success) {
                            success(status);
                        }
                    } failure:failure];
                }
            }
            if (self.channelType == nil) {
                NSLog(@"Service %@ (id=%@) does not support user defined channels. You must set the channelTypeId.", service.displayName, service.serviceId);
                failure(nil);
            }
        } failure:^(ZNGError *error) {
            NSLog(@"Service ID is required.");
            failure(error);
        }];
    } else {
        ZNGNewMessage *newMessage = [self newMessageToService:self.toService forTypeClass:self.channelType.typeClass];
        newMessage.attachments = @[@{
                                       kAttachementContentTypeKey : kAttachementContentTypeParam,
                                       kAttachementBase64 : encodedString
                                       }];
        newMessage.channelTypeIds = @[self.channelType.channelTypeId];
        [self.session.messageClient sendMessage:newMessage success:^(ZNGMessage *message, ZNGStatus *status) {
            if (success) {
                success(status);
            }
        } failure:failure];
    }
}

- (ZNGNewMessage *)newMessageToService:(BOOL)toService forTypeClass:(NSString *)typeClass
{
    ZNGNewMessage *newMessage = [[ZNGNewMessage alloc] init];
    
    NSString *serviceChannelValue = [typeClass isEqualToString:@"UserDefinedChannel"] ? nil : self.serviceChannelValue;

    if (toService) {
        newMessage.senderType = kConversationContact;
        newMessage.sender = [ZNGParticipant participantForContactId:self.contactId withContactChannelValue:self.contactChannelValue];
        newMessage.recipientType = kConversationService;
        newMessage.recipients = @[[ZNGParticipant participantForServiceId:self.serviceId withServiceChannelValue:serviceChannelValue]];
    } else {
        newMessage.senderType = kConversationService;
        newMessage.sender = [ZNGParticipant participantForServiceId:self.serviceId withServiceChannelValue:serviceChannelValue];
        newMessage.recipientType = kConversationContact;
        newMessage.recipients = @[[ZNGParticipant participantForContactId:self.contactId withContactChannelValue:self.contactChannelValue]];
    }
    
    return newMessage;
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

@end
