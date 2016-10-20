//
//  ZNGInboxDataSet.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataSet.h"
#import "ZNGLogging.h"
#import "ZNGContactClient.h"
#import "ZNGStatus.h"
#import "ZingleSDK.h"

static const int zngLogLevel = ZNGLogLevelDebug;

NSString * const ParameterKeyPageIndex              = @"page";
NSString * const ParameterKeyPageSize               = @"page_size";
NSString * const ParameterKeySortField              = @"sort_field";
NSString * const ParameterKeySortDirection          = @"sort_direction";
NSString * const ParameterKeyLastMessageCreatedAt   = @"last_message_created_at";
NSString * const ParameterKeyIsConfirmed            = @"is_confirmed";
NSString * const ParameterKeyIsClosed               = @"is_closed";
NSString * const ParameterKeyLabelId                = @"label_id";
NSString * const ParameterKeyQuery                  = @"query";
NSString * const ParameterKeyIsStarred              = @"is_starred";
NSString * const ParameterKeySearchMessageBodies    = @"search_message_bodies";


NSString * const ParameterValueTrue                 = @"true";
NSString * const ParameterValueFalse                = @"false";
NSString * const ParameterValueGreaterThanZero      = @"greater_than(0)";
NSString * const ParameterValueDescending           = @"desc";
NSString * const ParameterValueLastMessageCreatedAt = @"last_message_created_at";

// Readonly property re-declarations to ensure that they are properly backed with KVO compliant setters.
@interface ZNGInboxDataSet ()
@property (nonatomic, assign) BOOL loadingInitialData;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong, nonnull) NSOrderedSet<ZNGContact *> * contacts;

// Private property.  Used to avoid having to do some weak->totalPageCount nonsense within our NSOperationQueue operations.
@property (nonatomic, assign) NSUInteger totalPageCount;
@end

@implementation ZNGInboxDataSet
{
    BOOL loadedInitialData;
    
    NSOperationQueue * fetchQueue;
    
    ZNGContact * lastLocallyRemovedContact;
}

- (nonnull instancetype) initWithContactClient:(ZNGContactClient *)aContactClient
{
    self = [super init];
    
    if (self != nil) {
        _contactClient = aContactClient;
        
        fetchQueue = [[NSOperationQueue alloc] init];
        fetchQueue.name = @"Zingle Inbox fetching";
        fetchQueue.maxConcurrentOperationCount = 1;
        
        _contacts = [[NSOrderedSet alloc] init];
        _pageSize = 25;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshDueToPushNotification:) name:ZNGPushNotificationReceived object:nil];
    }
    
    return self;
}

- (void) dealloc
{
    [fetchQueue cancelAllOperations];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (NSString *) description
{
    return @"Unfiltered inbox data";
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@: %p>", [self class], self];
}

#pragma mark - Filtering
- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [[NSMutableDictionary alloc] init];
    parameters[ParameterKeyPageSize] = @(self.pageSize);
    parameters[ParameterKeySortField] = ParameterValueLastMessageCreatedAt;
    parameters[ParameterKeySortDirection] = ParameterValueDescending;
    parameters[ParameterKeyLastMessageCreatedAt] = ParameterValueGreaterThanZero;

    return parameters;
}

- (BOOL) isEqual:(ZNGInboxDataSet *)object
{
    if (![object isKindOfClass:[ZNGInboxDataSet class]]) {
        return NO;
    }
    
    return [[self parameters] isEqualToDictionary:[object parameters]];
}

#pragma mark - Loading data
- (void) refresh
{
    if (!loadedInitialData) {
        self.loadingInitialData = YES;
        self.loading = YES;
        loadedInitialData = YES;
    }
    
    [self refreshStartingAtIndex:0 removingTail:YES];
}

- (void) refreshDueToPushNotification:(NSNotification *)notification
{
    // TODO: Remove this delay once the elastic cloud something is re-ordered.  Ask Nathan.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshStartingAtIndex:0 removingTail:NO];
    });
}

- (void) refreshStartingAtIndex:(NSUInteger)index removingTail:(BOOL)removeTail
{
    // Calculate what page indices should be loaded in order to load some data starting at the specified index.
    
    NSUInteger pageSize = self.pageSize;
    NSMutableOrderedSet<NSNumber *> * pagesToRefresh = [[NSMutableOrderedSet alloc] init];
    NSUInteger loadedCount = [_contacts count];
    NSUInteger lastPageToLoad = (index / pageSize) + 1; // The page holding the object at the specified index
    NSUInteger totalPageCount = self.totalPageCount;
    
    // Sanity check how many pages we plan to load if we have any existing pagination data.
    if ((totalPageCount > 0) && (lastPageToLoad > totalPageCount)) {
        ZNGLogWarn(@"A request was made to load up to the %ld page of data, but we only expect to have %ld pages total.  This may fire off several requests that will return no data.",
                   (unsigned long)lastPageToLoad, (unsigned long)totalPageCount);
        
        // If the value is total nonsense, ignore it
        if ((lastPageToLoad - totalPageCount) > 10) {
            ZNGLogError(@"Refusing to request extra pages of data beyond expected index.");
            return;
        }
    }
    
    // First, we are going to need the page that holds the object at this specific index
    [pagesToRefresh addObject:@(lastPageToLoad)];
    
    // If the index they requested would load fewer than 10 entries, load an additional page
    NSUInteger remainingCountPastIndexOnPage = pageSize - (index % pageSize);
    
    if (remainingCountPastIndexOnPage < 10) {
        // Ensure that we are not appending an extra page beyond the actual data
        if ((totalPageCount == 0) || (lastPageToLoad+1 < totalPageCount)) {
            [pagesToRefresh addObject:@(lastPageToLoad + 1)];
        }
    }
    
    // Do we need to load any data leading up to this data?  (e.g. They requested object #25 but we have only loaded the first 10 objects.  Since our data is held in an
    //  array, we need the missing values first.)
    if (index > loadedCount) {
        NSUInteger firstPageToLoad = (loadedCount / pageSize) + 1;
        
        for (NSUInteger i = lastPageToLoad - 1; i >= firstPageToLoad; i--) {
            [pagesToRefresh insertObject:@(i) atIndex:0];
        }
    }
    
    if ([pagesToRefresh count] == 0) {
        // Nothing to refresh
        ZNGLogInfo(@"Refresh was called to start with index of %ld, but there is no additional data available (%ld total items.)", (unsigned long)index, (unsigned long)totalPageCount);
        return;
    }
    
    [self fetchPages:[pagesToRefresh array] removingTail:removeTail];
}

- (void) fetchPages:(NSArray<NSNumber *> *)pages removingTail:(BOOL)removeTail
{
    self.loading = YES;
    __weak ZNGInboxDataSet * weakSelf = self;
    __weak ZNGContactClient * weakContactClient = self.contactClient;
    
    // Create an NSBlockOperation for each page to fetch.  Feed them into the fetchQueue so that they will run one at a time in order.
    // Using NSBlockOperation also allows proper cancellation if we are deallocated.  This is a very real concern, especially when doing
    //  filtering based on a live-typed search term.  (We can expect many ZNGInboxDataSearch objects to be created and destroyed as the
    //  user types.)
    for (NSNumber * pageNumber in pages) {
        __block NSBlockOperation * operation = [NSBlockOperation blockOperationWithBlock:^{
            // Grab a strong reference to the client before we set our semaphore
            ZNGContactClient * strongContactClient = weakContactClient;
            
            // Ensure we are still on schedule and our contact client has not disappeared
            if ((operation.cancelled) || (strongContactClient == nil)) {
                return;
            }
            
            // Semaphore to keep the task alive and spinning until we receive a response
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            
            NSMutableDictionary * parameters = [weakSelf parameters];
            parameters[ParameterKeyPageIndex] = pageNumber;
            
            ZNGLogInfo(@"%@ (%p) is loading page #%@ of data...", [weakSelf class], weakSelf, pageNumber);
            
            [strongContactClient contactListWithParameters:parameters success:^(NSArray<ZNGContact *> *contacts, ZNGStatus *status) {
                weakSelf.totalPageCount = status.totalPages;
                weakSelf.count = status.totalRecords;
                
                // Add a contact client link to all contacts
                for (ZNGContact * contact in contacts) {
                    contact.contactClient = strongContactClient;
                }
                
                if (!(operation.cancelled)) {
                    [weakSelf mergeNewData:contacts withStatus:status];
                }
                dispatch_semaphore_signal(semaphore);
            } failure:^(ZNGError *error) {
                ZNGLogWarn(@"Unable to fetch inbox data for page %@: %@", pageNumber, error);
                dispatch_semaphore_signal(semaphore);
            }];
            
            dispatch_time_t thirtySecondTimeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC));
            dispatch_semaphore_wait(semaphore, thirtySecondTimeout);
        }];
        
        [fetchQueue addOperation:operation];
    }
    
    // Remove any data past this current refresh if appropriate
    if (removeTail) {
        __block NSBlockOperation * removeTailOperation = [NSBlockOperation blockOperationWithBlock:^{
            if (removeTailOperation.cancelled) {
                return;
            }
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSUInteger indexAfterCurrentData = [[pages lastObject] longValue] * weakSelf.pageSize;
                
                if (indexAfterCurrentData < [weakSelf.contacts count]) {
                    NSMutableOrderedSet<ZNGContact *> * mutable = [weakSelf mutableOrderedSetValueForKey:NSStringFromSelector(@selector(contacts))];
                    NSRange removalRange = NSMakeRange(indexAfterCurrentData, [mutable count] - indexAfterCurrentData);
                    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:removalRange];
                    
                    ZNGLogVerbose(@"Removing %ld objects that occur past the current refresh range.", (unsigned long)removalRange.length);
                    
                    [mutable removeObjectsAtIndexes:indexSet];
                }
            });
        }];
        
        [fetchQueue addOperation:removeTailOperation];
    }
    
    [fetchQueue addOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            ZNGInboxDataSet * strongSelf = weakSelf;
            
            strongSelf.loading = NO;
            
            if (strongSelf != nil) {
                strongSelf->lastLocallyRemovedContact = nil;
            }
        });
    }];
}

- (void) mergeNewData:(NSArray<ZNGContact *> *)incomingContacts withStatus:(ZNGStatus *)status
{
    if (![[NSThread currentThread] isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self mergeNewData:incomingContacts withStatus:status];
        });
        return;
    }
    
    if ([incomingContacts count] == 0) {
        ZNGLogDebug(@"Received 0 contacts in response");
        
        if ((status.totalRecords == 0) && ([self.contacts count] > 0)) {
            NSMutableOrderedSet * mutableContacts = [self mutableOrderedSetValueForKey:NSStringFromSelector(@selector(contacts))];
            [mutableContacts removeAllObjects];
        }
        
        self.loadingInitialData = NO;
        self.loading = NO;
        self.count = status.totalRecords;
        self.totalPageCount = status.totalPages;
        
        return;
    }
    
    // If this data contains a duder that we just removed locally, get rid of him.
    if ([incomingContacts containsObject:lastLocallyRemovedContact]) {
        NSMutableArray * mutableIncoming = [incomingContacts mutableCopy];
        [mutableIncoming removeObject:lastLocallyRemovedContact];
        status.totalRecords = status.totalRecords - 1;
        incomingContacts = mutableIncoming;
    }
    
    // Grab our mutable proxy object
    NSMutableOrderedSet<ZNGContact *> * mutableContacts = [self mutableOrderedSetValueForKey:NSStringFromSelector(@selector(contacts))];
    
    NSUInteger oldDataCount = [mutableContacts count];
    NSUInteger startIndex = (status.page - 1) * status.pageSize;
    
    // Check for the most simple and common case: We have brand new data to append.
    if (startIndex >= [self.contacts count]) {
        // Sanity check
        if (startIndex > [self.contacts count]) {
            ZNGLogWarn(@"Incoming data starts at index %ld, but we only have %ld items in our current data.  Appending anyway (at incorrect indices.)", (unsigned long)startIndex, (unsigned long)oldDataCount);
        }
        
        ZNGLogVerbose(@"Appending %ld objects that all appear outside of our current range.", (unsigned long)[incomingContacts count]);
        
        // Append all of the objects.
        // Note that insertObjects:atIndexes: is used instead of addObjectsFromArray: because the latter does one by one updates, causing
        //  tons of individual KVO notifications to be posted.
        NSRange indexRange = NSMakeRange([mutableContacts count], [incomingContacts count]);
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:indexRange];
        [mutableContacts insertObjects:incomingContacts atIndexes:indexSet];
        
    } else {
        // We have some overlap between our current data and this data.
        NSUInteger overlapFinalIndex = MIN(oldDataCount, startIndex + [incomingContacts count]);
        NSRange overlapRange = NSMakeRange(startIndex, overlapFinalIndex - startIndex);
        
        NSInteger overflowCount = [incomingContacts count] - overlapRange.length;
        NSArray * replacements = incomingContacts;

        if (overflowCount > 0) {
            replacements = [replacements subarrayWithRange:NSMakeRange(0, overlapRange.length)];
        }
        
        ZNGLogVerbose(@"We received %ld contacts, %ld of which extend past our current data.", (unsigned long)[incomingContacts count], (long)overflowCount);
        
        // We have two very specific simple cases that result from refreshes.
        //  1) One message has moved to the head
        //  2) All messages are still in order, but one (almost always one) or more needs to be refreshed
        BOOL simpleReorderingOrRefresh = NO;
        if ((overflowCount == 0) && ([incomingContacts count] >= 2)) {
            NSArray<ZNGContact *> * oldPage = [[mutableContacts array] subarrayWithRange:overlapRange];
            
            if ([[oldPage firstObject] isEqualToContact:incomingContacts[1]]) {
                // This looks like a simple new-contact-to-head move so far.  Our first object has moved down by one.
                // If we can find our new head somewhere else, we can do a simple swap.
                ZNGContact * firstNewContact = [incomingContacts firstObject];
                BOOL newHeadFoundInOldData = [mutableContacts containsObject:firstNewContact];
                
                if (newHeadFoundInOldData) {
                    // This looks like a simple reordering!  Hooray!
                    simpleReorderingOrRefresh = YES;
                    ZNGLogVerbose(@"Moving contact from a later position to head");
                    
                    [mutableContacts removeObject:firstNewContact];
                    [mutableContacts insertObject:firstNewContact atIndex:0];
                }
            } else if ([oldPage isEqualToArray:incomingContacts]) {
                simpleReorderingOrRefresh = YES;
                
                // Our contacts are all the same.  Replace any of the ones that need refreshing.  In practice, this will only be the very first object
                //  99% of the time.  It's technically possible for messages to be received in inbox order to cause refreshes in place for more than one.
                [oldPage enumerateObjectsUsingBlock:^(ZNGContact * _Nonnull contact, NSUInteger idx, BOOL * _Nonnull stop) {
                    ZNGContact * newContact = incomingContacts[idx];
                    
                    if ([newContact changedSince:contact]) {
                        ZNGLogDebug(@"Refreshing %@, last updated %.0f seconds ago", [newContact fullName], [[NSDate date] timeIntervalSinceDate:newContact.updatedAt]);
                        [mutableContacts replaceObjectAtIndex:idx+startIndex withObject:incomingContacts[idx]];
                    } else {
                        ZNGLogVerbose(@"Failing to replace %@ since the updated at timestamp has not changed.", [contact fullName]);
                    }
                }];
            }
        }
        
        if (!simpleReorderingOrRefresh) {
            // Replace the overlapping objects
            NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:overlapRange];
            [mutableContacts replaceObjectsAtIndexes:indexSet withObjects:replacements];
            
            // Append any extra
            if (overflowCount > 0) {
                NSRange overflowRange = NSMakeRange(overlapRange.length, [incomingContacts count] - overlapRange.length);
                NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:overflowRange];
                NSArray * overflow = [incomingContacts subarrayWithRange:overflowRange];
                [mutableContacts insertObjects:overflow atIndexes:indexSet];    // See note above about insertObjects:AtIndexes: vs. addObjectsFromArray; re: KVO
            }
        }
    }
    
    self.loadingInitialData = NO;
    self.count = status.totalRecords;
    self.totalPageCount = status.totalPages;
}

#pragma mark - Local changes
- (void) contactWasChangedLocally:(ZNGContact *)contact
{
    BOOL stillBelongsInThisDataSet = [self contactBelongsInDataSet:contact];
    BOOL wasPresent = [self.contacts containsObject:contact];
    
    if ((!stillBelongsInThisDataSet) && (wasPresent)) {
        ZNGLogInfo(@"Removing %@ from our current data set due to a local change.", [contact fullName]);
        NSMutableOrderedSet * mutableContacts = [self mutableOrderedSetValueForKey:NSStringFromSelector(@selector(contacts))];
        self.count = self.count - 1;
        [mutableContacts removeObject:contact];
        lastLocallyRemovedContact = contact;
    } else {
        if (wasPresent) {
            NSMutableOrderedSet * mutableContacts = [self mutableOrderedSetValueForKey:NSStringFromSelector(@selector(contacts))];
            NSUInteger contactIndex = [mutableContacts indexOfObject:contact];
            [mutableContacts replaceObjectAtIndex:contactIndex withObject:contact];
        }
        
        lastLocallyRemovedContact = nil;
    }
}

- (BOOL) contactBelongsInDataSet:(ZNGContact *)contact
{
    // Default implementation is YES, since we do not yet discriminate.
    return YES;
}

@end
