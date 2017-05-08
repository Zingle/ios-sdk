//
//  ZNGConversation.m
//  Pods
//
//  Created by Ryan Farley on 2/18/16.
//
//

#import "ZNGConversation.h"
#import "ZingleAccountSession.h"
#import "ZNGEvent.h"
#import "ZNGEventClient.h"
#import "ZNGEventViewModel.h"
#import "ZNGMessageClient.h"
#import "ZNGServiceClient.h"
#import "ZingleSession.h"
#import "ZNGLogging.h"
#import "ZNGNewMessageResponse.h"
#import "ZNGAnalytics.h"
#import <ImageIO/ImageIO.h>
#import "UIImage+animatedGIF.h"
#import "NSData+ImageType.h"

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
NSString *const kAttachmentContentTypeKey = @"content_type";
NSString *const kAttachementBase64 = @"base64";
NSString *const kConversationService = @"service";
NSString *const kConversationContact = @"contact";
NSString *const kMessageDirectionInbound = @"inbound";
NSString *const kMessageDirectionOutbound = @"outbound";

static const CGFloat imageAttachmentMaxWidth = 800.0;
static const CGFloat imageAttachmentMaxHeight = 800.0;

- (id) initWithMessageClient:(ZNGMessageClient *)messageClient eventClient:(ZNGEventClient *)eventClient
{
    NSParameterAssert(messageClient);
    NSParameterAssert(eventClient);
    
    self = [super init];
    
    if (self != nil) {
        _events = @[];
        _eventViewModels = @[];
        _messageClient = messageClient;
        _eventClient = eventClient;
        _pageSize = kDefaultPageSize;
        _automaticallyRefreshesOnPushNotification = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyPushNotificationReceived:) name:ZNGPushNotificationReceived object:nil];
    }
    
    return self;
}

- (id) initWithConversation:(ZNGConversation *)conversation
{
    self = [self initWithMessageClient:conversation.messageClient eventClient:conversation.eventClient];

    if (self != nil) {
        self.lockedDescription = conversation.lockedDescription;
    }
    
    return self;
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
    if (self.loading) {
        ZNGLogInfo(@"Ignoring call to loadRecentEventsErasingOlderData: because a load is already in progress.");
        return;
    }
    
    // If we already have some data, and the caller does not wish old data blown away, we will first fetch a page size of 0 to see if we have more data
    if ((!replace) && (self.totalEventCount > 0)) {
        NSDictionary * parameters = [self parametersForPageSize:0 pageIndex:1];
        
        [self.eventClient eventListWithParameters:parameters success:^(NSArray<ZNGEvent *> *events, ZNGStatus *status) {
            if (status.totalRecords > self.totalEventCount) {
                ZNGLogDebug(@"There appears to be more event data available (%lld vs our local count of %lld.)  Fetching...", (long long)status.totalRecords, (long long)self.totalEventCount);
                self.totalEventCount = status.totalRecords;
                [self _loadRecentEventsErasing:replace];
            } else {
                ZNGLogDebug(@"There are still only %lld events available.", (long long)status.totalRecords);
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
    if (self.loading) {
        ZNGLogInfo(@"Ignoring call to loadRecentEventsErasingOlderData: because a load is already in progress.");
        return;
    }
    
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
    NSMutableArray<ZNGEventViewModel *> * viewModels = [[NSMutableArray alloc] init];
    
    for (ZNGEvent * event in events) {
        [viewModels addObjectsFromArray:event.viewModels];
    }
    
    // Use insertion instead of addObjectsFromArray to get one batched KVO update
    NSMutableArray<ZNGEvent *> * mutableEvents = [self mutableArrayValueForKey:NSStringFromSelector(@selector(events))];
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([mutableEvents count], [events count])];
    [mutableEvents insertObjects:events atIndexes:indexSet];
    
    NSMutableArray<ZNGEventViewModel *> * mutableViewModels = [self mutableArrayValueForKey:NSStringFromSelector(@selector(eventViewModels))];
    indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([mutableViewModels count], [viewModels count])];
    [mutableViewModels insertObjects:viewModels atIndexes:indexSet];
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
    
    NSMutableArray<ZNGEventViewModel *> * mutableViewModels = [self mutableArrayValueForKey:NSStringFromSelector(@selector(eventViewModels))];
    NSMutableArray<ZNGEventViewModel *> * newViewModels = [[NSMutableArray alloc] init];
    for (ZNGEvent * event in incomingEventsMinusOverlap) {
        [newViewModels addObjectsFromArray:event.viewModels];
    }
    
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [incomingEventsMinusOverlap count])];
    [mutableEvents insertObjects:incomingEventsMinusOverlap atIndexes:indexSet];
    
    indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [newViewModels count])];
    [mutableViewModels insertObjects:newViewModels atIndexes:indexSet];
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

- (BOOL) pushNotificationRelevantToThisConversation:(NSNotification *)notification
{
    return YES;
}

- (void) notifyPushNotificationReceived:(NSNotification *)notification
{
    if ((self.automaticallyRefreshesOnPushNotification) && ([self pushNotificationRelevantToThisConversation:notification])) {
        [self loadRecentEventsErasingOlderData:NO];
    }
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

- (void) removeAnyPendingMessages
{
    NSMutableIndexSet * pendingIndexes = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet * pendingViewModelIndexes = [[NSMutableIndexSet alloc] init];
    
    [self.events enumerateObjectsUsingBlock:^(ZNGEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
        if (event.sending) {
            [pendingIndexes addIndex:idx];
        }
    }];
    
    [self.eventViewModels enumerateObjectsUsingBlock:^(ZNGEventViewModel * _Nonnull viewModel, NSUInteger idx, BOOL * _Nonnull stop) {
        if (viewModel.event.sending) {
            [pendingViewModelIndexes addIndex:idx];
        }
    }];
    
    if ([pendingIndexes count] > 0) {
        ZNGLogDebug(@"Removing %llu pending messages.", (unsigned long long)[pendingIndexes count]);
        NSMutableArray * mutableEvents = [self mutableArrayValueForKey:NSStringFromSelector(@selector(events))];
        [mutableEvents removeObjectsAtIndexes:pendingIndexes];
        
        NSMutableArray * mutableViewModels = [self mutableArrayValueForKey:NSStringFromSelector(@selector(eventViewModels))];
        [mutableViewModels removeObjectsAtIndexes:pendingViewModelIndexes];
    }
}

- (void)sendMessageWithBody:(NSString *)body
                    success:(void (^)(ZNGStatus* status))success
                    failure:(void (^) (ZNGError *error))failure
{
    [self sendMessageWithBody:body imageData:nil uuid:nil success:success failure:failure];
}

- (void) sendMessageWithBody:(nonnull NSString *)body
                   imageData:(nullable NSArray<NSData *> *)imageDatas
                        uuid:(NSString *)uuid
                     success:(void (^_Nullable)(ZNGStatus* _Nullable status))success
                     failure:(void (^_Nullable) (ZNGError * _Nullable error))failure
{
    ZNGNewMessage *newMessage = [self freshMessage];
    
    if (newMessage == nil) {
        NSDictionary * userInfo = @{ NSLocalizedDescriptionKey : @"Unable to initialize a fresh outgoing message" };
        ZNGError * error = [[ZNGError alloc] initWithDomain:kZingleErrorDomain code:0 userInfo:userInfo];
        
        if (failure != nil) {
            failure(error);
        }
        
        return;
    }
    
    newMessage.body = body;
    newMessage.uuid = uuid;
    self.loading = YES;
    ZNGParticipant * recipient = [newMessage.recipients firstObject];
    ZNGLogVerbose(@"Sending \"%@\" to %@", body, recipient.channelValue);
    
    if ([imageDatas count] == 0) {
        [self _sendMessage:newMessage success:success failure:failure];
        return;
    }
    
    // We have one or more image attachments
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // We need the image data in two places for each image:
        //  1) an array of UIImage objects that our UI can display as the image sends
        //  2) a base 64 encoded image attachment in an attachment dictionary
        NSMutableArray<UIImage *> * outgoingImageObjects = [[NSMutableArray alloc] initWithCapacity:[imageDatas count]];
        NSMutableArray<NSDictionary *> * outgoingAttachments = [[NSMutableArray alloc] initWithCapacity:[imageDatas count]];
        
        for (NSData * originalImageData in imageDatas) {
            // Sanity check
            if ([originalImageData length] == 0) {
                continue;
            }
            
            // Image data and content type will be the same as the original source unless we resize
            NSData * imageData = originalImageData;
            NSString * contentType = [originalImageData imageContentType];
            
            UIImage * imageForLocalDisplay;

            CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFTypeRef)imageData, NULL);
            size_t const frameCount = CGImageSourceGetCount(imageSource);
            
            if (frameCount > 1) {
                // This is an animated GIF.  We need to make an animated UIImage for display while the message sends
                imageForLocalDisplay = [UIImage animatedImageWithAnimatedGIFData:originalImageData];
                contentType = NSDataImageContentTypeGif;
            } else {
                // This is a single frame image.  We will resize if necessary.
                
                // Note that our locally-displayed copy (only while the message is being sent) is not the resized version.  This should not particularly matter.
                imageForLocalDisplay = [[UIImage alloc] initWithData:imageData];
                
                if ((imageForLocalDisplay.size.height > imageAttachmentMaxHeight) || (imageForLocalDisplay.size.width > imageAttachmentMaxWidth)) {
                    NSData * resizedData = [self resizedJpegImageDataForImage:imageForLocalDisplay];
                    
                    if (resizedData != nil) {
                        imageData = resizedData;
                        contentType = NSDataImageContentTypeJpeg;
                    } else {
                        ZNGLogError(@"Unable to resize %@ image before sending.  It will be sent in its original form.", NSStringFromCGSize(imageForLocalDisplay.size));
                    }
                }
            }
            
            [outgoingImageObjects addObject:imageForLocalDisplay];
            
            NSData * base64Data = [imageData base64EncodedDataWithOptions:0];
            NSString * base64String = [[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding];
            NSDictionary * attachment = @{ kAttachmentContentTypeKey : contentType, kAttachementBase64 : base64String };
            
            [outgoingAttachments addObject:attachment];
        }
        
        newMessage.outgoingImageAttachments = outgoingImageObjects;
        newMessage.attachments = outgoingAttachments;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _sendMessage:newMessage success:success failure:failure];
        });
    });
}

- (ZNGEvent *)pendingMessageEventForOutgoingMessage:(ZNGNewMessage *)newMessage
{
    BOOL outbound = [newMessage.recipientType isEqualToString:ZNGConversationParticipantTypeContact];
    
    ZNGMessage * message = [[ZNGMessage alloc] init];
    message.body = newMessage.body;
    message.communicationDirection = outbound ? @"outbound" : @"inbound";
    message.senderType = outbound ? @"service" : @"contact";
    message.createdAt = [NSDate date];


    if ([self.messageClient.session isKindOfClass:[ZingleAccountSession class]]) {
        ZingleAccountSession * accountSession = (ZingleAccountSession *)self.messageClient.session;
        message.triggeredByUser = [ZNGUser userFromUserAuthorization:accountSession.userAuthorization];
    }
    
    if ([newMessage.outgoingImageAttachments count] > 0) {
        NSMutableArray * nullImageLinks = [[NSMutableArray alloc] initWithCapacity:[newMessage.outgoingImageAttachments count]];
        
        for (NSUInteger i=0; i < [newMessage.outgoingImageAttachments count]; i++) {
            [nullImageLinks addObject:[NSNull null]];
        }
        
        message.attachments = nullImageLinks;
        message.outgoingImageAttachments = newMessage.outgoingImageAttachments;
    }
    
    ZNGEvent * event = [ZNGEvent eventForNewMessage:message];
    [self addSenderNameToEvents:@[event]];
    
    [event createViewModels];
    
    return event;
}

- (void) _sendMessage:(ZNGNewMessage *)message success:(void (^)(ZNGStatus* status))success failure:(void (^) (ZNGError *error))failure
{
    ZNGEvent * pendingEvent = [self pendingMessageEventForOutgoingMessage:message];
    
    if (pendingEvent != nil) {
        NSMutableArray * mutableEvents = [self mutableArrayValueForKey:NSStringFromSelector(@selector(events))];
        [mutableEvents addObject:pendingEvent];
        
        NSMutableArray * mutableViewModels = [self mutableArrayValueForKey:NSStringFromSelector(@selector(eventViewModels))];
        [mutableViewModels addObjectsFromArray:pendingEvent.viewModels];
    } else {
        ZNGLogError(@"Unable to generate pending message event object.  Message will not appear as an in progress message.");
    }
    
    [self.messageClient sendMessage:message success:^(ZNGNewMessageResponse *newMessageResponse, ZNGStatus *status) {
        
        NSString * messageId = [[newMessageResponse messageIds] firstObject];
        
        if (![messageId isKindOfClass:[NSString class]]) {
            ZNGLogError(@"Message send reported success, but we did not receive a message ID in response.  Our new message will not appear in the conversation until it is refreshed elsewhere.");
            
            if (success) {
                success(status);
            }
            
            return;
        }
        
        // Slight delay so we're not 2fast2furious for the server.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSDictionary * params = [self parametersForPageSize:self.pageSize pageIndex:1];
            [self.eventClient eventListWithParameters:params success:^(NSArray<ZNGEvent *> *events, ZNGStatus *status) {
                [self removeAnyPendingMessages];
                self.totalEventCount = status.totalRecords;
                
                // Since we are fetching our data in descending order (so page 1 has recent data,) we need to reverse for proper chronological order
                NSArray<ZNGEvent *> * sortedEvents = [[events reverseObjectEnumerator] allObjects];
                
                [self mergeNewDataAtTail:sortedEvents];
                self.loading = NO;
                
                if (success) {
                    success(status);
                }
            } failure:^(ZNGError *error) {
                [self removeAnyPendingMessages];
                ZNGLogError(@"Message send reported success, but we were unable to load event data afterwards.  This is odd.  %@", error);
                self.loading = NO;
                
                if (success) {
                    success(status);
                }
            }];
        });
    } failure:^(ZNGError *error) {
        [self removeAnyPendingMessages];
        self.loading = NO;
        
        if (failure != nil) {
            failure(error);
        }
    }];
}

-(NSData *)resizedJpegImageDataForImage:(UIImage *)image
{
    // Sanity check
    if ((image.size.height == 0) || (image.size.width == 0)) {
        return nil;
    }
    
    // If the image is animated, abandon all hope (of resize)
    if ([image.images count] > 1) {
        return nil;
    }

    CGFloat widthDownscale = imageAttachmentMaxWidth / image.size.width;
    CGFloat heightDownscale = imageAttachmentMaxHeight / image.size.height;
    CGFloat downscale = MIN(widthDownscale, heightDownscale);
    
    if (downscale >= 1.0) {
        // No need to resize
        return nil;
    }
    
    CGFloat newWidth = image.size.width * downscale;
    CGFloat newHeight = image.size.height * downscale;
    
    CGRect rect = CGRectMake(0.0, 0.0, newWidth, newHeight);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    UIImage * resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    float compressionQuality = 0.5;
    NSData * imageData = UIImageJPEGRepresentation(resizedImage, compressionQuality);
    UIGraphicsEndImageContext();
    
    return imageData;
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
