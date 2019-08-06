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
#import "ZNGNewMessageResponse.h"
#import "ZNGAnalytics.h"
#import <ImageIO/ImageIO.h>
#import "UIImage+animatedGIF.h"
#import "NSData+ImageType.h"
#import "ZNGPendingResponseOrNote.h"
#import "ZNGUserAuthorization.h"

@import SBObjectiveCWrapper;

static const NSUInteger kDefaultPageSize = 100;

// How long should a user remain in the replyingUsers array after a notification?
static const NSTimeInterval userTypingIndicatorLifetime = 5.0;

NSString * const ZNGConversationParticipantTypeContact = @"contact";
NSString * const ZNGConversationParticipantTypeService = @"service";
NSString * const ZNGConversationParticipantTypeLabel = @"label";
NSString * const ZNGConversationParticipantTypeGroup = @"contact_group";

@interface NSIndexSet (Continuity)
- (BOOL) isContinuous;
@end

@implementation NSIndexSet (Continuity)

- (BOOL) isContinuous
{
    __block BOOL continuous = YES;
    __block NSUInteger lastIndex = [self firstIndex];
    
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        // Is this the first item?
        if (idx == lastIndex) {
            return; // continue
        }
        
        if (idx != lastIndex + 1) {
            continuous = NO;
            *stop = YES;
            return;
        }
        
        lastIndex = idx;
    }];
    
    return continuous;
}

@end

@interface ZNGConversation ()
@property (nonatomic, strong, nonnull) NSOrderedSet * replyingUsers;
@end

@implementation ZNGConversation
{
    // Weak table of NSTimers used to remove typing indicator users.
    // Keyed by user ID.
    NSMapTable * typingIndicatorUserExpirationTimers;
}

NSString * const kConversationPage = @"page";
NSString * const kConversationPageSize = @"page_size";
NSString * const kConversationContactId = @"contact_id";
NSString * const kConversationSortFields = @"sort_fields";
NSString * const kConversationSortDirection = @"sort_direction";
NSString * const kConversationSortDirectionAscending = @"asc";
NSString * const kConversationSortDirectionDescending = @"desc";
NSString * const kConversationIsDelayed = @"is_delayed";
NSString * const kConversationCreatedAt = @"created_at";
NSString * const kConversationUpdatedAt = @"updated_at";
NSString * const kConversationExecuteAt = @"execute_at";
NSString * const kConversationId = @"id";
NSString * const kConversationEventType = @"event_type";
NSString * const kConversationService = @"service";
NSString * const kConversationContact = @"contact";
NSString * const kMessageDirectionInbound = @"inbound";
NSString * const kMessageDirectionOutbound = @"outbound";

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
        _automaticallyRefreshes = YES;
        
        _replyingUsers = [[NSOrderedSet alloc] init];
        typingIndicatorUserExpirationTimers = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zng_notifyConversationDataReceived:) name:ZingleConversationDataArrivedNotification object:nil];
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
        SBLogError(@"Page size must be non-zero.  Ignoring new value.");
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
        SBLogInfo(@"Ignoring call to loadRecentEventsErasingOlderData: because a load is already in progress.");
        return;
    }
    
    // If we already have some data, and the caller does not wish old data blown away, we will first fetch a page size of 0 to see if we have more data
    if ((!replace) && (self.totalEventCount > 0)) {
        NSDictionary * parameters = [self parametersForPageSize:0 pageIndex:1];
        
        [self.eventClient eventListWithParameters:parameters success:^(NSArray<ZNGEvent *> *events, ZNGStatus *status) {
            if (status.totalRecords > self.totalEventCount) {
                SBLogDebug(@"There appears to be more event data available (%lld vs our local count of %lld.)  Fetching...", (long long)status.totalRecords, (long long)self.totalEventCount);
                self.totalEventCount = status.totalRecords;
                [self _loadRecentEventsErasing:replace removingSendingEvents:NO success:nil failure:nil];
            } else if ([self lastPageContainsMutableEvent]) {
                // We are going to load our most recent page of data.  If our event count has decreased, we will also blow away any
                //  existing data at the same time.
                BOOL countDecreased = (status.totalRecords < self.totalEventCount);
                
                SBLogInfo(@"We have one or more deletable event types in data.  Total event count was %llu and is now %llu. \
                           Reloading most recent data...", (unsigned long long)self.totalEventCount, (unsigned long long)status.totalRecords);
                [self _loadRecentEventsErasing:countDecreased removingSendingEvents:NO success:nil failure:nil];
            } else {
                SBLogDebug(@"There are still only %lld events available.", (long long)status.totalRecords);
            }
        } failure:^(ZNGError *error) {
            SBLogError(@"Unable to retrieve status from empty event request.  Loading all data, since we cannot tell if we have any new data.");
            [self _loadRecentEventsErasing:replace removingSendingEvents:NO success:nil failure:nil];
        }];
    } else {
        // We have no special logic for this case.  Go get the data.
        [self _loadRecentEventsErasing:replace removingSendingEvents:NO success:nil failure:nil];
    }
}

- (BOOL) lastPageContainsMutableEvent
{
    NSInteger i = ([self.events count] <= self.pageSize) ? 0 : ([self.events count] - self.pageSize);
    
    while (i < [self.events count]) {
        if ([self.events[i] isMutable]) {
            return YES;
        }
        
        i++;
    }
    
    return NO;
}

- (void)_loadRecentEventsErasing:(BOOL)replace removingSendingEvents:(BOOL)removeSending  success:(void (^)(ZNGStatus* status))success failure:(void (^) (ZNGError *error))failure
{
    // Avoid double loading.  If our caller is relying on us to remove sending events on success or failure,
    //  we will go ahead and double load.
    if ((self.loading) && (!removeSending)) {
        SBLogInfo(@"Ignoring call to loadRecentEventsErasingOlderData: because a load is already in progress.");
        return;
    }
    
    NSDictionary * params = [self parametersForPageSize:self.pageSize pageIndex:1];
    self.loading = YES;
    
    [self.eventClient eventListWithParameters:params success:^(NSArray<ZNGEvent *> *events, ZNGStatus *status) {
        if (removeSending) {
            [self removeSendingEvents];
        }
        
        if (!self.loadedInitialData) {
            self.loadedInitialData = YES;
        }
        
        self.totalEventCount = status.totalRecords;
        
        // Since we are fetching our data in descending order (so page 1 has recent data,) we need to reverse for proper chronological order
        NSArray<ZNGEvent *> * sortedEvents = [[events reverseObjectEnumerator] allObjects];
        
        if (replace) {
            NSMutableArray<ZNGEvent *> * mutableEvents = [self mutableArrayValueForKey:NSStringFromSelector(@selector(events))];
            [mutableEvents removeAllObjects];
        }
        
        [self mergeNewDataAtTail:sortedEvents];
        self.loading = NO;
        
        if (success) {
            success(status);
        }
    } failure:^(ZNGError *error) {
        if (removeSending) {
            [self removeSendingEvents];
        }
        
        SBLogError(@"Unable to load events: %@", error);
        self.loading = NO;
        
        if (failure != nil) {
            failure(error);
        }
    }];
}

- (void) mergeMutableEventsFromNewData:(NSArray<ZNGEvent *> *)incomingEvents
{
    NSInteger startingIndex = ([self.events count] <= self.pageSize) ? 0 : ([self.events count] - self.pageSize);
    BOOL foundPreviousEventInNewData = NO;
    NSMutableArray<ZNGEvent *> * eventsToDelete = [[NSMutableArray alloc] init];

    for (NSInteger i = startingIndex; i < [self.events count]; i++) {
        ZNGEvent * oldEvent = self.events[i];
        NSUInteger newEventIndex = [incomingEvents indexOfObject:oldEvent];
        
        if (newEventIndex == NSNotFound) {
            // The old event from our data is not present in this new data.  Was it deleted?
            // Unless we are looking at the case of an event slipping off the most recent page of data, the event is gone.
            
            if (foundPreviousEventInNewData) {
                // We found the last event in this new data.  The lack of this event in new data indicates that the event is deleted.
                [eventsToDelete addObject:oldEvent];
            }
            
            foundPreviousEventInNewData = NO;
            continue;
        }
        
        foundPreviousEventInNewData = YES;
        ZNGEvent * newEvent = incomingEvents[newEventIndex];
        
        if ((![newEvent isMutable]) && (![oldEvent isMutable])) {
            // This is an immutable event
            continue;
        }
        
        if ([newEvent hasChangedSince:oldEvent]) {
            NSMutableArray<ZNGEvent *> * mutableEvents = [self mutableArrayValueForKey:NSStringFromSelector(@selector(events))];
            [mutableEvents replaceObjectAtIndex:i withObject:newEvent];
            
            NSMutableIndexSet * oldViewModelIndexes = [[NSMutableIndexSet alloc] init];
            NSMutableArray<ZNGEventViewModel *> * mutableViewModels = [self mutableArrayValueForKey:NSStringFromSelector(@selector(eventViewModels))];
            
            [mutableViewModels enumerateObjectsUsingBlock:^(ZNGEventViewModel * _Nonnull viewModel, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([viewModel.event isEqual:oldEvent]) {
                    [oldViewModelIndexes addIndex:idx];
                }
            }];
            
            if ([oldViewModelIndexes count] == 0) {
                SBLogError(@"Unable to find updated event in view models array even though it was found in the events array.  Help.");
                return;
            }
            
            [mutableViewModels removeObjectsAtIndexes:oldViewModelIndexes];
            NSArray<ZNGEventViewModel *> * newViewModels = newEvent.viewModels;
            
            NSIndexSet * viewModelIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([oldViewModelIndexes firstIndex], [newViewModels count])];
            [mutableViewModels insertObjects:newViewModels atIndexes:viewModelIndexes];
        }
    }
    
    if ([eventsToDelete count] > 0) {
        [self _removeDeletedEvents:eventsToDelete];
    }
}

- (void) _removeDeletedEvents:(NSArray<ZNGEvent *> *)eventsToDelete
{
    for (ZNGEvent * event in eventsToDelete) {
        NSMutableArray<ZNGEvent *> * mutableEvents = [self mutableArrayValueForKey:NSStringFromSelector(@selector(events))];
        NSMutableArray<ZNGEventViewModel *> * mutableViewModels = [self mutableArrayValueForKey:NSStringFromSelector(@selector(eventViewModels))];
        
        NSMutableIndexSet * viewModelIndexesToDelete = [[NSMutableIndexSet alloc] init];
        
        [mutableViewModels enumerateObjectsUsingBlock:^(ZNGEventViewModel * _Nonnull viewModel, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([viewModel.event isEqual:event]) {
                // This view model corresponds to the event we are deleting
                [viewModelIndexesToDelete addIndex:idx];
            }
        }];
        
        [mutableEvents removeObject:event];
        [mutableViewModels removeObjectsAtIndexes:viewModelIndexesToDelete];
    }
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
    
    // Take care of any mutable events
    if ([self lastPageContainsMutableEvent]) {
        [self mergeMutableEventsFromNewData:incomingEvents];
    }
    
    NSMutableOrderedSet<ZNGEvent *> * newEvents = [[NSMutableOrderedSet alloc] initWithArray:incomingEvents];
    NSOrderedSet<ZNGEvent *> * oldEvents = [[NSOrderedSet alloc] initWithArray:self.events];
    [newEvents minusOrderedSet:oldEvents];
    
    if ([newEvents count] == 0) {
        // No new events.  It is odd that we made it this far, but this should be harmless.
        SBLogInfo(@"%s was called, but no new event data was found.", __PRETTY_FUNCTION__);
        return;
    }
    
    NSMutableIndexSet * indexesOfNewEventsInIncomingEvents = [[NSMutableIndexSet alloc] init];
    
    for (ZNGEvent * event in newEvents) {
        [indexesOfNewEventsInIncomingEvents addIndex:[incomingEvents indexOfObject:event]];
    }
    
    if (![indexesOfNewEventsInIncomingEvents isContinuous]) {
        SBLogError(@"%s was called, but there is a non-continuous delta between our old data and this new data.  This would likely cause duplicate event data.\n\
                      Reloading all data.", __PRETTY_FUNCTION__);
        _loading = NO;  // Remove loading flag without triggering KVO so that the load below is not skipped.
        [self loadRecentEventsErasingOlderData:YES];
        return;
    }
    
    // Check for this data being inserted somewhere other than the tail.  This happens, for instance, if there is a delayed message that always appears at
    //  the end of our data.  New messages will arrive just above these delayed messages.
    NSUInteger indexJustBelowNewData = [indexesOfNewEventsInIncomingEvents lastIndex] + 1;
    
    if ([incomingEvents count] > indexJustBelowNewData) {
        ZNGEvent * eventJustBelowNewData = incomingEvents[indexJustBelowNewData];
        
        // The index in our total data just below where our new data is to be inserted
        NSUInteger postInsertionIndex = [self.events indexOfObject:eventJustBelowNewData];
        
        if (postInsertionIndex != NSNotFound) {
            // Find the same index in our view models array that we just found in our events array.
            // This may be more than one if eventJustBelowNewData has more than one view model.
            NSIndexSet * viewModelPostInsertionIndexes = [self.eventViewModels indexesOfObjectsPassingTest:^BOOL(ZNGEventViewModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [obj.event isEqual:eventJustBelowNewData];
            }];
            
            if ([viewModelPostInsertionIndexes count] == 0) {
                SBLogError(@"Unable to find our insertion target event in the view models array.  Something has gone wacky.  Clearing all data and reloading...");
                _loading = NO;  // Remove loading flag without triggering KVO so that the load below is not skipped.
                [self loadRecentEventsErasingOlderData:YES];
                return;
            }
            
            NSMutableArray<ZNGEvent *> * mutableEvents = [self mutableArrayValueForKey:NSStringFromSelector(@selector(events))];
            NSIndexSet * insertionIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(postInsertionIndex, [newEvents count])];
            [mutableEvents insertObjects:[newEvents array] atIndexes:insertionIndexSet];
            
            NSMutableArray<ZNGEventViewModel *> * newViewModels = [[NSMutableArray alloc] init];
            for (ZNGEvent * event in newEvents) {
                [newViewModels addObjectsFromArray:event.viewModels];
            }
            
            NSMutableArray<ZNGEventViewModel *> * mutableViewModels = [self mutableArrayValueForKey:NSStringFromSelector(@selector(eventViewModels))];
            NSIndexSet * viewModelInsertionIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([viewModelPostInsertionIndexes firstIndex], [newViewModels count])];
            [mutableViewModels insertObjects:newViewModels atIndexes:viewModelInsertionIndexSet];
            
            return;
        } else {
            SBLogWarning(@"We expected the new %llu events appearing in this new data to be inserted above our tail, but we were unable to find the event below this new data.  Appending new data to tail..",
                       (unsigned long long)[newEvents count]);
            // Fall through to the appendEvents: below
        }
    }
    
    // Normal append.
    [self appendEvents:[newEvents array]];
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
        SBLogInfo(@"loadOlderData called with no existing data.  Fetching initial data...");
        [self loadRecentEventsErasingOlderData:NO];
        return;
    }
    
    if ([self.events count] >= self.totalEventCount) {
        SBLogInfo(@"loadOlderData called, but there is no data available beyond our current %llu items.", (unsigned long long)[self.events count]);
        return;
    }
    
    NSUInteger lastPageAlreadyFetched = [self.events count] / self.pageSize;
    NSUInteger nextPageToFetch = lastPageAlreadyFetched + 1;
    
    if (([self.events count] % self.pageSize) != 0) {
        SBLogWarning(@"Our current event data does not fall on page boundaries.  The older data loaded will not fill an entire page.");
        nextPageToFetch++;
    }
    
    NSDictionary * parameters = [self parametersForPageSize:self.pageSize pageIndex:nextPageToFetch];
    
    self.loading = YES;
    
    [self.eventClient eventListWithParameters:parameters success:^(NSArray<ZNGEvent *> *events, ZNGStatus *status) {
        
        self.totalEventCount = status.totalRecords;
        
        SBLogDebug(@"Loaded %llu more events", (unsigned long long)[events count]);
        
        NSArray<ZNGEvent *> * sortedEvents = [[events reverseObjectEnumerator] allObjects];
        [self mergeNewDataAtHead:sortedEvents];
        self.loading = NO;
    } failure:^(ZNGError *error) {
        SBLogError(@"Unable to load older event data: %@", error);
        self.loading = NO;
    }];
}

- (void) mergeNewDataAtHead:(NSArray<ZNGEvent *> *)incomingEvents
{
    [self addSenderNameToEvents:incomingEvents];
    [self addMissingMessageIdsToMessageEvents:incomingEvents];
    
    if ([self.events count] == 0) {
        SBLogWarning(@"mergeNewDataAtHead: called without any existing data.  This was probably accidental.");
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
    NSString * isDelayedSort = [NSString stringWithFormat:@"%@ %@", kConversationIsDelayed, kConversationSortDirectionDescending];
    NSString * executeAtSort = [NSString stringWithFormat:@"%@ %@", kConversationExecuteAt, kConversationSortDirectionDescending];
    NSString * updatedAtSort = [NSString stringWithFormat:@"%@ %@", kConversationUpdatedAt, kConversationSortDirectionDescending];
    NSString * idSort = [NSString stringWithFormat:@"%@ %@", kConversationId, kConversationSortDirectionDescending];

    NSMutableDictionary * params = [@{
                                     kConversationPageSize : @(pageSize),
                                     kConversationContactId : contactId,
                                     kConversationPage: @(pageIndex),
                                     kConversationSortFields : @[isDelayedSort, executeAtSort, updatedAtSort, idSort],
                                     kConversationSortDirection: kConversationSortDirectionDescending,
                                     } mutableCopy];
    
    if ([eventTypes count] > 0) {
        params[kConversationEventType] = eventTypes;
    }
    
    return params;
}

- (NSArray<NSString *> *)eventTypes
{
    // Default implementation is just messages
    return @[ZNGEventTypeMessage];
}

- (BOOL) notificationRelevantToThisConversation:(NSNotification *)notification
{
    return YES;
}

- (void) zng_notifyConversationDataReceived:(NSNotification *)notification
{
    if ((self.automaticallyRefreshes) && ([self notificationRelevantToThisConversation:notification])) {
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

- (ZNGMessage *) priorMessage:(ZNGMessage *)message
{
    NSUInteger i = [self.events indexOfObjectPassingTest:^BOOL(ZNGEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
        return ([event.message isEqual:message]);
    }];
    
    if (i == NSNotFound) {
        SBLogWarning(@"priorMessage to message %@ was requested, but that message itself cannot be found in this conversation's %llu events",
                     message.messageId, (unsigned long long)[self.events count]);
        return nil;
    }
    
    if (i == 0) {
        // This is the very first event
        return nil;
    }
    
    do {
        i--;
        ZNGEvent * event = self.events[i];
        
        if ([event isMessage]) {
            return self.events[i].message;
        }
    } while (i != 0);
    
    return nil;
}

- (ZNGMessage *) priorMessageWithSameDirection:(ZNGMessage *)message
{
    BOOL isOutbound = [message isOutbound];
    ZNGMessage * priorMessage = message;
    
    while (YES) {
        priorMessage = [self priorMessage:priorMessage];
        
        if (priorMessage == nil) {
            // No more prior messages
            return nil;
        }
        
        if ([priorMessage isOutbound] == isOutbound) {
            return priorMessage;
        }
    }
    
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
            SBLogDebug(@"Messages marked as read.");
        } else {
            SBLogError(@"Failed to mark messages marked as read. statusCode = %ld", (long)status.statusCode);
        }
                                                 
    } failure:^(ZNGError *error) {
            SBLogError(@"Error marking messages as read. Error = %@", error.localizedDescription);
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

- (void) removeSendingEvents
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
        SBLogDebug(@"Removing %llu pending messages.", (unsigned long long)[pendingIndexes count]);
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
                     failure:(void (^_Nullable)(ZNGError * _Nullable error))failure
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
    SBLogVerbose(@"Sending \"%@\" to %@", body, recipient.channelValue);
    
    if ([imageDatas count] == 0) {
        [self _sendMessage:newMessage success:success failure:failure];
        return;
    }
    
    // We have one or more image attachments
    // Hop onto a background thread and create the attachments
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSData * imageData in imageDatas) {
            [newMessage attachImageData:imageData withMaximumSize:CGSizeZero removingExisting:NO];
        }
        
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
        message.triggeredByUser = accountSession.userAuthorization;
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
        SBLogError(@"Unable to generate pending message event object.  Message will not appear as an in progress message.");
    }
    
    [self.messageClient sendMessage:message success:^(ZNGNewMessageResponse *newMessageResponse, ZNGStatus *status) {
        
        NSString * messageId = [[newMessageResponse messageIds] firstObject];
        
        if (![messageId isKindOfClass:[NSString class]]) {
            SBLogError(@"Message send reported success, but we did not receive a message ID in response.  Our new message will not appear in the conversation until it is refreshed elsewhere.");
            
            if (success) {
                success(status);
            }
            
            return;
        }
        
        // Slight delay so we're not 2fast2furious for the server.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self _loadRecentEventsErasing:NO removingSendingEvents:YES success:^(ZNGStatus * _Nullable status) {
                if (success != nil) {
                    success(status);
                }
            } failure:^(ZNGError * _Nullable error) {
                SBLogWarning(@"Message send succeeded, but retrieving data afterward failed.  This is probably fine: %@", error);
                
                if (success != nil) {
                    success(status);
                }
            }];
        });
    } failure:^(ZNGError *error) {
        [self removeSendingEvents];
        self.loading = NO;
        
        if (failure != nil) {
            failure(error);
        }
    }];
}



#pragma mark - Typing indicator
- (void) otherUserIsReplying:(ZNGUser * _Nonnull)user isInternalNote:(BOOL)isNote
{
    if ([user.userId length] == 0) {
        SBLogError(@"%s called with no user ID: %@", __PRETTY_FUNCTION__, user);
        return;
    }

    // Add the dude
    NSString * eventType = (isNote) ? ZNGPendingResponseTypeInternalNote : ZNGPendingResponseTypeMessage;
    ZNGPendingResponseOrNote * pendingResponse = [[ZNGPendingResponseOrNote alloc] initWithUser:user eventType:eventType];
    NSMutableOrderedSet<ZNGPendingResponseOrNote *> * mutableRespondingUsers = [self mutableOrderedSetValueForKey:NSStringFromSelector(@selector(pendingResponses))];
    [mutableRespondingUsers addObject:pendingResponse];
    
    // Cancel any timer that would have removed him from an earlier notification
    NSTimer * previousTimerThisUser = [typingIndicatorUserExpirationTimers objectForKey:user.userId];
    [previousTimerThisUser invalidate];
    
    NSTimer * newTimer;
    
    // Set a timer to remove him after some time.
    // Use weak timers if they are available.
    if (@available(iOS 10.0, *)) {
        __weak ZNGConversation * weakSelf = self;
        newTimer = [NSTimer scheduledTimerWithTimeInterval:userTypingIndicatorLifetime repeats:NO block:^(NSTimer * _Nonnull timer) {
            [weakSelf _removeRespondingUser:pendingResponse];
        }];
    } else {
        // We cannot easily use a weak timer, so we'll use a normal timer.  This means that we will persist for, at most, five seconds beyond
        //  when we would normally be deallocated.
        newTimer = [NSTimer scheduledTimerWithTimeInterval:userTypingIndicatorLifetime target:self selector:@selector(_removeRespondingUserFromTimer:) userInfo:pendingResponse repeats:NO];
    }
    
    [typingIndicatorUserExpirationTimers setObject:newTimer forKey:user.userId];
}

- (void) _removeRespondingUserFromTimer:(NSTimer *)timer
{
    ZNGPendingResponseOrNote * pendingResponse = timer.userInfo;
    [self _removeRespondingUser:pendingResponse];
}

- (void) _removeRespondingUser:(ZNGPendingResponseOrNote *)pendingResponse
{
    NSMutableOrderedSet<ZNGPendingResponseOrNote *> * mutableRespondingUsers = [self mutableOrderedSetValueForKey:NSStringFromSelector(@selector(pendingResponses))];
    [mutableRespondingUsers removeObject:pendingResponse];
}

#pragma mark - Protected/Abstract methods

- (NSString *)remoteName
{
    SBLogWarning(@"Using empty implementation of %s", __PRETTY_FUNCTION__);
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
