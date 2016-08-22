//
//  ZNGConversation.m
//  Pods
//
//  Created by Ryan Farley on 2/18/16.
//
//

#import "ZNGConversation.h"
#import "ZNGEvent.h"
#import "ZNGEventClient.h"
#import "ZNGMessageClient.h"
#import "ZNGServiceClient.h"
#import "ZingleSession.h"
#import "ZNGLogging.h"
#import "ZNGNewMessageResponse.h"

static const int zngLogLevel = ZNGLogLevelVerbose;

NSString * const ZNGConversationParticipantTypeContact = @"contact";
NSString * const ZNGConversationParticipantTypeService = @"service";

@interface ZNGConversation ()

@property (nonatomic) NSInteger pagesLeftToLoad;

@end

@implementation ZNGConversation

NSString *const kConversationPage = @"page";
NSString *const kConversationPageSize = @"page_size";
NSString *const kConversationContactId = @"contact_id";
NSString *const kConversationSortField = @"sort_field";
NSString *const kConversationCreatedAt = @"created_at";
NSString *const kConversationEventType = @"event_type";
NSString *const kAttachementContentTypeKey = @"content_type";
NSString *const kAttachementContentTypeParam = @"image/png";
NSString *const kAttachementBase64 = @"base64";
NSString *const kConversationService = @"service";
NSString *const kConversationContact = @"contact";
NSString *const kMessageDirectionInbound = @"inbound";
NSString *const kMessageDirectionOutbound = @"outbound";

- (id) initWithMessageClient:(ZNGMessageClient *)messageClient eventClient:(ZNGEventClient *)eventClient
{
    NSParameterAssert(messageClient);
    NSParameterAssert(eventClient);
    
    self = [super init];
    
    if (self != nil) {
        _events = @[];
        _messageClient = messageClient;
        _eventClient = eventClient;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyPushNotificationReceived:) name:ZNGPushNotificationReceived object:nil];
    }
    
    return self;
}

- (id) initWithConversation:(ZNGConversation *)conversation
{
    return [self initWithMessageClient:conversation.messageClient eventClient:conversation.eventClient];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL) isEqual:(ZNGConversation *)other
{
    if (![other isKindOfClass:[ZNGConversation class]]) {
        return NO;
    }
    
    return [[self eventTypes] isEqualToArray:[other eventTypes]];
}

- (NSUInteger) hash
{
    return [[self eventTypes] hash];
}

- (void)updateEvents
{   
    void (^fetchNewData)() = ^{
        NSDictionary *params = [self parametersForPageSize:100 pageIndex:1];
        
        [self.eventClient eventListWithParameters:params success:^(NSArray<ZNGEvent *> *events, ZNGStatus *status) {
            ZNGLogVerbose(@"Received event list with %ld events.  We previously had %ld.", (unsigned long)status.totalRecords, (unsigned long)self.totalEventCount);

            if (status.totalRecords == self.totalEventCount) {
                // We have no new messages
                return;
            }
            
            self.totalEventCount = status.totalRecords;
            self.pagesLeftToLoad = status.totalPages - 1;
            [self mergeNewEventsAtTail:events];
            
            if (self.pagesLeftToLoad > 0) {
                [self loadNextPage:status.page + 1];
            }
            
        } failure:^(ZNGError *error) {
            ZNGLogError(@"Event client failed to retrieve events: %@", error);
        }];
    };
    
    // If we already have some data, we will request a page size of 0 first to check if we even have new data
    if (self.totalEventCount > 0) {
        NSDictionary * params = [self parametersForPageSize:0 pageIndex:1];
        
        [self.eventClient eventListWithParameters:params success:^(NSArray<ZNGEvent *> *events, ZNGStatus *status) {
            ZNGLogDebug(@"There are %ld total events available.  We currently have %ld.", (long)status.totalRecords, (long)self.totalEventCount);
            
            if (status.totalRecords > self.totalEventCount) {
                ZNGLogDebug(@"Requesting new data.");
                fetchNewData();
            }
        } failure:^(ZNGError *error) {
            ZNGLogError(@"Unable to retrieve status from empty event request.  Loading all data, since we cannot tell if we have any new data.");
            fetchNewData();
        }];
    } else {
        fetchNewData();
    }
}

- (NSDictionary *) parametersForPageSize:(NSUInteger)pageSize pageIndex:(NSUInteger)pageIndex
{
    NSArray<NSString *> * eventTypes = [self eventTypes];

    NSMutableDictionary * params = [@{
                                     kConversationPageSize : @(pageSize),
                                     kConversationContactId : contactId,
                                     kConversationPage: @(pageIndex),
                                     kConversationSortField : kConversationCreatedAt,
                                     } mutableCopy];
    
    if ([eventTypes count] > 0) {
        params[kConversationEventType] = eventTypes;
    }
    
    return params;
}

- (NSArray<NSString *> *)eventTypes
{
    // Default implementation is just messages
    return @[@"message"];
}

- (void) notifyPushNotificationReceived:(NSNotification *)notification
{
    [self updateEvents];
}

- (void) mergeNewEventsAtTail:(NSArray<ZNGEvent *> *)events
{
    [self addSenderNameToMessageEvents:events];
    [self addMissingMessageIdsToMessageEvents:events];
    
    NSMutableArray * mutableEvents = [self mutableArrayValueForKey:NSStringFromSelector(@selector(events))];

    if ([mutableEvents count] == 0) {
        // We need to append this data
        NSRange newEventRange = NSMakeRange([mutableEvents count], [events count]);
        NSIndexSet * indexSet = [[NSIndexSet alloc] initWithIndexesInRange:newEventRange];
        [mutableEvents insertObjects:events atIndexes:indexSet];
        return;
    }
    
    
    NSUInteger indexOfLastOldEventInNewEvents = [events indexOfObject:[mutableEvents lastObject]];
    
    if (indexOfLastOldEventInNewEvents == NSNotFound) {
        // We were unable to find matching data anywhere.  Blow away our old array and use this new one.
        [self willChangeValueForKey:NSStringFromSelector(@selector(events))];
        _events = events;
        [self didChangeValueForKey:NSStringFromSelector(@selector(events))];
        return;
    }

    NSArray * newTail = [events subarrayWithRange:NSMakeRange(indexOfLastOldEventInNewEvents + 1, [events count] - indexOfLastOldEventInNewEvents - 1)];
    NSRange destinationRange = NSMakeRange([mutableEvents count], [newTail count]);
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:destinationRange];
    [mutableEvents insertObjects:newTail atIndexes:indexSet];
}

- (void) appendEvents:(NSArray<ZNGEvent *> *)events
{
    [self addSenderNameToMessageEvents:events];
    [self addMissingMessageIdsToMessageEvents:events];
    
    NSMutableArray * mutableEvents = [self mutableArrayValueForKey:NSStringFromSelector(@selector(events))];
    NSRange range = NSMakeRange([mutableEvents count], [events count]);
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    [mutableEvents insertObjects:events atIndexes:indexSet];
}

- (void) addSenderNameToMessageEvents:(NSArray<ZNGEvent *> *)events
{
    NSAssert(NO, @"Failed to implement required method: %s", __PRETTY_FUNCTION__);
}

- (void) addMissingMessageIdsToMessageEvents:(NSArray <ZNGEvent *> *)events
{
    for (ZNGEvent * event in events) {
        if ([event isMessage]) {
            if ([event.message.messageId length] == 0) {
                event.message.messageId = event.eventId;
            }
            
            if (event.message.triggeredByUser == nil) {
                event.message.triggeredByUser = event.triggeredByUser;
            }
        }
    }
}

- (void)loadNextPage:(NSInteger)page
{
    if (page < 1) {
        ZNGLogError(@"loadNextPage called with invalid page number of %ld", (long)page);
        return;
    }
    
    NSDictionary * params = [self parametersForPageSize:100 pageIndex:page];
    
    [self.eventClient eventListWithParameters:params success:^(NSArray<ZNGEvent *> *events, ZNGStatus *status) {
        [self appendEvents:events];
        self.pagesLeftToLoad--;
        
        if (self.pagesLeftToLoad >= 1) {
            [self loadNextPage:status.page + 1];
        }
    } failure:nil];
}

#pragma mark - Data retrieval
- (ZNGMessage *) priorMessageWithSameDirection:(ZNGMessage *)message
{
    NSUInteger index = [self.events indexOfObjectPassingTest:^BOOL(ZNGEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
        return ([event.message isEqual:message]);
    }];
    
    if ((index == NSNotFound) || (index == 0)) {
        // This is the first
        return nil;
    }
    
    BOOL isOutbound = [message isOutbound];
    
    NSUInteger i = index;
    
    do {
        i--;
        ZNGEvent * testEvent = self.events[i];
        ZNGMessage * testMessage = testEvent.message;
        
        if ((testMessage != nil) && ([testMessage isOutbound] == isOutbound)) {
            return testMessage;
        }
    } while (i != 0);
    
    return nil;
}

- (ZNGMessage *) mostRecentInboundMessage
{
    for (ZNGEvent * event in self.events) {
        if (([event isMessage]) && (event.message) != nil && (![event.message isOutbound])) {
            return event.message;
        }
    }
    
    return nil;
}

- (ZNGMessage *) mostRecentMessage
{
    for (ZNGEvent * event in self.events) {
        if ([event isMessage]) {
            return event.message;
        }
    }
    
    return nil;
}

#pragma mark - Actions
- (void)markMessagesAsRead:(NSArray<ZNGMessage *> *)messages;
{
    NSMutableArray *messageIds = [[NSMutableArray alloc] init];
    NSDate *readAt = [NSDate date];
    
    // Build a list of message Ids to mark as read.
    for (ZNGMessage *message in messages) {
        
        if (message.readAt == nil) {
        
            // Set the readAt property so we don't mark this message as read again.
            message.readAt = readAt;
            
            [messageIds addObject:message.messageId];
        }
    }
    
    if ([messageIds count] == 0) {
        return;
    }

    [self.messageClient markMessagesReadWithMessageIds:messageIds
                                              readAt:readAt
                                             success:^(ZNGStatus *status) {
        if (status.statusCode == 200) {
            ZNGLogDebug(@"Messages marked as read.");
        } else {
            ZNGLogError(@"Failed to mark messages marked as read. statusCode = %ld", (long)status.statusCode);
        }
                                                 
    } failure:^(ZNGError *error) {
            ZNGLogError(@"Error marking messages as read. Error = %@", error.localizedDescription);
    }];
}

- (void)markAllUnreadMessagesAsRead
{
    NSMutableArray<ZNGMessage *> * allMessages = [[NSMutableArray alloc] init];
    
    for (ZNGEvent * event in self.events) {
        if (event.message != nil) {
            [allMessages addObject:event.message];
        }
    }
    
    [self markMessagesAsRead:allMessages];
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
            [self appendEvents:@[[ZNGEvent eventForNewMessage:message]]];
            self.totalEventCount = self.totalEventCount + 1;
            
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
                    [self appendEvents:@[[ZNGEvent eventForNewMessage:message]]];
                    self.totalEventCount = self.totalEventCount + 1;
                    
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
