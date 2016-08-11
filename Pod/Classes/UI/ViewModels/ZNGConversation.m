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

static const NSUInteger kDefaultPageSize = 100;

NSString * const ZNGConversationParticipantTypeContact = @"contact";
NSString * const ZNGConversationParticipantTypeService = @"service";
NSString * const ZNGConversationParticipantTypeLabel = @"label";

@implementation ZNGConversation

NSString *const kConversationPage = @"page";
NSString *const kConversationPageSize = @"page_size";
NSString *const kConversationContactId = @"contact_id";
NSString *const kConversationSortField = @"sort_field";
NSString *const kConversationSortDirection = @"sort_direction";
NSString *const kConversationSortDirectionAscending = @"asc";
NSString *const kConversationSortDirectionDescending = @"desc";
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
        _pageSize = kDefaultPageSize;
        
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

- (void) setPageSize:(NSUInteger)pageSize
{
    if (pageSize == 0) {
        ZNGLogError(@"Page size must be non-zero.  Ignoring new value.");
        return;
    }
    
    _pageSize = pageSize;
}

- (NSUInteger) hash
{
    return [[self eventTypes] hash];
}

#pragma mark - Refreshing latest data
- (void)loadRecentEventsErasingOlderData:(BOOL)replace
{
    // If we already have some data, and the caller does not wish old data blown away, we will first fetch a page size of 0 to see if we have more data
    if ((!replace) && (self.totalEventCount > 0)) {
        NSDictionary * parameters = [self parametersForPageSize:0 pageIndex:1];
        
        self.loading = YES;
        [self.eventClient eventListWithParameters:parameters success:^(NSArray<ZNGEvent *> *events, ZNGStatus *status) {
            
            if (status.totalRecords != self.totalEventCount) {
                ZNGLogDebug(@"There appears to be more event data available.  Fetching...");
                self.totalEventCount = status.totalRecords;
                [self _loadRecentEventsErasing:replace];
            } else {
                ZNGLogDebug(@"There are still only %llu events available.", (unsigned long long)status.totalRecords);
                self.loading = NO;
            }
            
        } failure:^(ZNGError *error) {
            ZNGLogError(@"Unable to retrieve status from empty event request.  Loading all data, since we cannot tell if we have any new data.");
            [self _loadRecentEventsErasing:replace];
        }];
    } else {
        // We have no special logic for this case.  Go get the data.
        [self _loadRecentEventsErasing:replace];
    }
}

- (void)_loadRecentEventsErasing:(BOOL)replace
{
    NSDictionary * params = [self parametersForPageSize:self.pageSize pageIndex:1];
    self.loading = YES;
    
    [self.eventClient eventListWithParameters:params success:^(NSArray<ZNGEvent *> *events, ZNGStatus *status) {
        
        self.totalEventCount = status.totalRecords;
        
        // Since we are fetching our data in descending order (so page 1 has recent data,) we need to reverse for proper chronological order
        NSArray<ZNGEvent *> * sortedEvents = [[events reverseObjectEnumerator] allObjects];
        
        if (replace) {
            NSMutableArray<ZNGEvent *> * mutableEvents = [self mutableArrayValueForKey:NSStringFromSelector(@selector(events))];
            [mutableEvents removeAllObjects];
        }
        
        [self mergeNewDataAtTail:sortedEvents];
        self.loading = NO;
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Unable to load events: %@", error);
        self.loading = NO;
    }];
}

- (void)mergeNewDataAtTail:(NSArray<ZNGEvent *> *)incomingEvents
{
    [self addSenderNameToEvents:incomingEvents];
    [self addMissingMessageIdsToMessageEvents:incomingEvents];
    
    // If we have no existing data, this is pretty simple!
    if ([self.events count] == 0) {
        [self appendEvents:incomingEvents];
        return;
    }
    
    // We have new data for page 1 and some existing data.  We expect some overlap.
    // First we will find the index of the previous last object in this new data.
    NSUInteger previousNewestEventIndexInNewData = [incomingEvents indexOfObject:[self.events lastObject]];
    
    if (previousNewestEventIndexInNewData == NSNotFound) {
        // We could not find our previous newest even in this new data.  We will append all of this data to our tail.
        ZNGLogInfo(@"Received %llu new events but were unable to find any overlap.  There is likely missing data inbetween these pages.", (unsigned long long)[incomingEvents count]);
        [self appendEvents:incomingEvents];
        return;
    }
    
    // Ensure we actually have some new data.  Things have gone kooky somewhere earlier if this sanity test fails.
    if ([incomingEvents count] <= previousNewestEventIndexInNewData + 1) {
        ZNGLogWarn(@"We received %llu new events, but there appears to be no new data to append.", (unsigned long long)[incomingEvents count]);
        return;
    }
    
    NSRange incomingEventsFreshDataRange = NSMakeRange(previousNewestEventIndexInNewData + 1, [incomingEvents count] - previousNewestEventIndexInNewData - 1);
    NSArray<ZNGEvent *> * nonOverlappingIncomingEvents = [incomingEvents subarrayWithRange:incomingEventsFreshDataRange];
    [self appendEvents:nonOverlappingIncomingEvents];
}

- (void) appendEvents:(NSArray<ZNGEvent *> *)events
{
    // Use insertion instead of addObjectsFromArray to get one batched KVO update
    NSMutableArray<ZNGEvent *> * mutableEvents = [self mutableArrayValueForKey:NSStringFromSelector(@selector(events))];
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([mutableEvents count], [events count])];
    [mutableEvents insertObjects:events atIndexes:indexSet];
}

#pragma mark - Grabbing older data
- (void) loadOlderData
{
    if (self.totalEventCount == 0) {
        ZNGLogInfo(@"loadOlderData called with no existing data.  Fetching initial data...");
        [self loadRecentEventsErasingOlderData:NO];
        return;
    }
    
    if ([self.events count] >= self.totalEventCount) {
        ZNGLogInfo(@"loadOlderData called, but there is no data available beyond our current %llu items.", (unsigned long long)[self.events count]);
        return;
    }
    
    NSUInteger lastPageAlreadyFetched = [self.events count] / self.pageSize;
    NSUInteger nextPageToFetch = lastPageAlreadyFetched + 1;
    
    if (([self.events count] % self.pageSize) != 0) {
        ZNGLogWarn(@"Our current event data does not fall on page boundaries.  The older data loaded will not fill an entire page.");
        nextPageToFetch++;
    }
    
    NSDictionary * parameters = [self parametersForPageSize:self.pageSize pageIndex:nextPageToFetch];
    
    self.loading = YES;
    
    [self.eventClient eventListWithParameters:parameters success:^(NSArray<ZNGEvent *> *events, ZNGStatus *status) {
        
        self.totalEventCount = status.totalRecords;
        
        ZNGLogDebug(@"Loaded %llu more events", (unsigned long long)[events count]);
        
        NSArray<ZNGEvent *> * sortedEvents = [[events reverseObjectEnumerator] allObjects];
        [self mergeNewDataAtHead:sortedEvents];
        self.loading = NO;
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Unable to load older event data: %@", error);
        self.loading = NO;
    }];
}

- (void) mergeNewDataAtHead:(NSArray<ZNGEvent *> *)incomingEvents
{
    [self addSenderNameToEvents:incomingEvents];
    [self addMissingMessageIdsToMessageEvents:incomingEvents];
    
    if ([self.events count] == 0) {
        ZNGLogWarn(@"mergeNewDataAtHead: called without any existing data.  This was probably accidental.");
        [self appendEvents:incomingEvents];
        return;
    }
    
    NSMutableArray<ZNGEvent *> * mutableEvents = [self mutableArrayValueForKey:NSStringFromSelector(@selector(events))];
    NSUInteger indexOfOldHeadInNewData = [incomingEvents indexOfObject:[self.events firstObject]];
    NSArray<ZNGEvent *> * incomingEventsMinusOverlap = incomingEvents;
    
    // If we have overlap, crop our incoming data to only include the new stuff
    if (indexOfOldHeadInNewData != NSNotFound) {
        NSRange nonOverlapRange = NSMakeRange(0, indexOfOldHeadInNewData);
        incomingEventsMinusOverlap = [incomingEvents subarrayWithRange:nonOverlapRange];
    }
    
    // Do nothing if we have no data!
    if ([incomingEventsMinusOverlap count] == 0) {
        return;
    }
    
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [incomingEventsMinusOverlap count])];
    [mutableEvents insertObjects:incomingEventsMinusOverlap atIndexes:indexSet];
}

#pragma mark - Parameters/Settings
- (NSDictionary *) parametersForPageSize:(NSUInteger)pageSize pageIndex:(NSUInteger)pageIndex
{
    NSArray<NSString *> * eventTypes = [self eventTypes];

    // Note that sort order is set to descending so page 1 has most recent messages.  This data will then be reversed upon receipt.
    NSMutableDictionary * params = [@{
                                     kConversationPageSize : @(pageSize),
                                     kConversationContactId : contactId,
                                     kConversationPage: @(pageIndex),
                                     kConversationSortField : kConversationCreatedAt,
                                     kConversationSortDirection : kConversationSortDirectionDescending
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
    [self loadRecentEventsErasingOlderData:NO];
}

- (void) addSenderNameToEvents:(NSArray<ZNGEvent *> *)events
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

#pragma mark - Data retrieval
- (ZNGEvent *) priorEvent:(ZNGEvent *)event
{
    NSUInteger index = [self.events indexOfObject:event];
    
    if ((index != NSNotFound) && (index > 0)) {
        return self.events[index - 1];
    }
    
    return nil;
}

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
            ZNGLogError(@"Failed to mark messages marked as read. statusCode = %ld", status.statusCode);
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
    
    self.loading = YES;
    
    [self.messageClient sendMessage:newMessage success:^(ZNGNewMessageResponse *newMessageResponse, ZNGStatus *status) {
        
        NSString * messageId = [[newMessageResponse messageIds] firstObject];
        
        if (![messageId isKindOfClass:[NSString class]]) {
            ZNGLogError(@"Message send reported success, but we did not receive a message ID in response.  Our new message will not appear in the conversation until it is refreshed elsewhere.");
            
            self.loading = NO;
            
            if (success) {
                success(status);
            }
            
            return;
        }
        
        [self.messageClient messageWithId:messageId success:^(ZNGMessage *message, ZNGStatus *status) {
            ZNGEvent * event = [ZNGEvent eventForNewMessage:message];
            [self addSenderNameToEvents:@[event]];
            [self appendEvents:@[event]];
            self.totalEventCount = self.totalEventCount + 1;
            self.loading = NO;
            
            if (success) {
                success(status);
            }
        } failure:^(ZNGError *error) {
            ZNGLogWarn(@"Message send reported success, but we were unable to retrieve the message with the supplied ID of %@", messageId);
            
            self.loading = NO;
            
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(ZNGError *error) {
        self.loading = NO;
        
        if (failure != nil) {
            failure(error);
        }
    }];
}

- (void)sendMessageWithImage:(UIImage *)image
                     success:(void (^)(ZNGStatus* status))success
                     failure:(void (^) (ZNGError *error))failure
{
    self.loading = YES;
    
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
                    
                    self.loading = NO;
                    
                    if (success) {
                        success(status);
                    }
                } failure:^(ZNGError *error) {
                    ZNGLogWarn(@"Message send reported success, but we were unable to retrieve the message with the supplied ID of %@", messageId);
                    
                    self.loading = NO;
                    
                    if (failure) {
                        failure(error);
                    }
                }];
            } failure:^(ZNGError *error) {
                self.loading = NO;
                
                if (failure != nil) {
                    failure(error);
                }
            }];
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
