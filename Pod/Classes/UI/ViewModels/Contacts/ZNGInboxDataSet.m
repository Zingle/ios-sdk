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
#import "ZNGContactDataSetBuilder.h"
#import "ZNGLabel.h"
#import "ZingleAccountSession.h"

static const int zngLogLevel = ZNGLogLevelDebug;

static NSString * const ParameterKeyPageIndex              = @"page";
static NSString * const ParameterKeyPageSize               = @"page_size";
static NSString * const ParameterKeySortFields              = @"sort_fields";
static NSString * const ParameterKeyLastMessageCreatedAt   = @"last_message_created_at";
static NSString * const ParameterKeyIsConfirmed            = @"is_confirmed";
static NSString * const ParameterKeyIsClosed               = @"is_closed";
static NSString * const ParameterKeyUnassigned             = @"is_unassigned";
static NSString * const ParameterKeyAssignedUserId         = @"assigned_to_user_id";
static NSString * const ParameterKeyAssignedTeamId         = @"assigned_to_team_id";
static NSString * const ParameterKeyLabelId                = @"label_id";
static NSString * const ParameterKeyGroupId                = @"contact_group_id";
static NSString * const ParameterKeyQuery                  = @"query";
static NSString * const ParameterKeySearchMessageBodies    = @"search_message_bodies";
static NSString * const ParameterValueTrue                 = @"true";
static NSString * const ParameterValueFalse                = @"false";
static NSString * const ParameterValueGreaterThanZero      = @"greater_than(0)";

NSString * const ZNGInboxDataSetSortFieldContactCreatedAt = @"created_at";
NSString * const ZNGInboxDataSetSortFieldLastMessageCreatedAt = @"last_message_created_at";
NSString * const ZNGInboxDataSetSortFieldLastName = @"last_name";
NSString * const ZNGInboxDataSetSortDirectionAscending = @"asc";
NSString * const ZNGInboxDataSetSortDirectionDescending = @"desc";

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
    NSIndexSet * loadingPages;
    
    NSOperationQueue * fetchQueue;
    
    ZNGContact * lastLocallyRemovedContact;
}

+ (nonnull instancetype) dataSetWithBlock:(void (^ _Nonnull)(ZNGContactDataSetBuilder *))builderBlock
{
    NSParameterAssert(builderBlock);
    
    ZNGContactDataSetBuilder * builder = [[ZNGContactDataSetBuilder alloc] init];
    builderBlock(builder);
    return [builder build];
}

- (nonnull instancetype) init
{
    self = [super init];
    
    if (self != nil) {
        _sortFields = @[[NSString stringWithFormat:@"%@ %@", ZNGInboxDataSetSortFieldLastMessageCreatedAt, ZNGInboxDataSetSortDirectionDescending]];
        loadingPages = [[NSMutableIndexSet alloc] init];
    }
    
    return self;
}

- (nonnull instancetype) initWithBuilder:(ZNGContactDataSetBuilder *)builder
{
    NSParameterAssert(builder.contactClient);
    
    self = [self init];
    
    if (self != nil) {
        _contactClient = builder.contactClient;
        
        _pageSize = builder.pageSize;
        _allowContactsWithNoMessages = builder.allowContactsWithNoMessages;
        _openStatus = builder.openStatus;
        _unconfirmed = builder.unconfirmed;
        _labelIds = builder.labelIds;
        _groupIds = builder.groupIds;
        _searchText = builder.searchText;
        _searchMessageBodies = builder.searchMessageBodies;
        _unassigned = builder.unassigned;
        
        if (!_unassigned) {
            _assignedTeamId = builder.assignedTeamId;
            _assignedUserId = builder.assignedUserId;
            
            if (([_assignedTeamId length] > 0) && ([_assignedUserId length] > 0)) {
                ZNGLogError(@"Both team ID and user ID provided as assignment filters.  This is probably in error.");
            }
        } else {
            if (([builder.assignedTeamId length] > 0) || ([builder.assignedUserId length] > 0)) {
                ZNGLogError(@"Unassigned flag is set to YES, but there were team or user assignment IDs also provided.  They are ignored.");
            }
        }
        
        if ([builder.sortFields count] > 0) {
            _sortFields = builder.sortFields;
        }
        
        if (_pageSize == 0) {
            _pageSize = 25;
        }
        
        fetchQueue = [[NSOperationQueue alloc] init];
        fetchQueue.name = @"Zingle Inbox fetching";
        fetchQueue.maxConcurrentOperationCount = 1;
        
        _contacts = [[NSOrderedSet alloc] init];
    }
    
    return self;
}

- (void) dealloc
{
    [fetchQueue cancelAllOperations];
}

- (NSString *) description
{
    NSArray<NSString *> * descriptionItems = [self descriptionItems];
    NSUInteger count = [descriptionItems count];
    
    NSMutableString * description = [[NSMutableString alloc] initWithString:@"Inbox"];
    
    if (count > 0) {
        [description appendString:@": "];
        
        [descriptionItems enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [description appendString:obj];
            
            if (idx < (count - 1)) {
                [description appendString:@", "];
            }
        }];
    }

    return description;
}

- (NSArray<NSString *> *) descriptionItems
{
    NSMutableArray<NSString *> * words = [[NSMutableArray alloc] init];
    
    if (self.unassigned) {
        [words addObject:@"Unassigned"];
    } else if ([self.assignedTeamId length] > 0) {
        [words addObject:[NSString stringWithFormat:@"Assigned to team %@", self.assignedTeamId]];
    } else if ([self.assignedUserId length] > 0) {
        [words addObject:[NSString stringWithFormat:@"Assigned to user %@", self.assignedUserId]];
    }
    
    if (self.unconfirmed) {
        [words addObject:@"Unread"];
    }
    
    switch (self.openStatus) {
        case ZNGInboxDataSetOpenStatusClosed:
            [words addObject:@"Only closed"];
            break;
        case ZNGInboxDataSetOpenStatusBoth:
            [words addObject:@"Both open and closed"];
            break;
        default:
            // Open only is default, so we will not add anything to the description.
            break;
    }
    
    if ([self.searchText length] > 0) {
        [words addObject:[NSString stringWithFormat:@"Searching for \"%@\"", self.searchText]];
    }
    
    if ([self.labelIds count] > 0) {
        [words addObject:@"Searching label(s)"];
    }
    
    if ([self.groupIds count] > 0) {
        [words addObject:@"Searching group(s)"];
    }
    
    return words;
}

- (NSString *) title
{
    // TODO: Return a title
    return @"Contacts";
}

- (ZNGContactDataSetBuilder *)builder
{
    ZNGContactDataSetBuilder * builder = [[ZNGContactDataSetBuilder alloc] init];
    
    builder.pageSize = self.pageSize;
    builder.openStatus = self.openStatus;
    builder.unconfirmed = self.unconfirmed;
    builder.allowContactsWithNoMessages = self.allowContactsWithNoMessages;
    builder.sortFields = self.sortFields;
    builder.labelIds = self.labelIds;
    builder.groupIds = self.groupIds;
    builder.unassigned = self.unassigned;
    builder.assignedTeamId = self.assignedTeamId;
    builder.assignedUserId = self.assignedUserId;
    builder.searchText = self.searchText;
    builder.searchMessageBodies = self.searchMessageBodies;
    builder.contactClient = self.contactClient;
    
    return builder;
}

#pragma mark - Filtering
- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [[NSMutableDictionary alloc] init];
    parameters[ParameterKeyPageSize] = @(self.pageSize);
    
    parameters[ParameterKeySortFields] = self.sortFields;
    
    if (self.openStatus == ZNGInboxDataSetOpenStatusOpen) {
        parameters[ParameterKeyIsClosed] = ParameterValueFalse;
    } else if (self.openStatus == ZNGInboxDataSetOpenStatusClosed) {
        parameters[ParameterKeyIsClosed] = ParameterValueTrue;
    } // else both, so no value for is_closed
    
    if (self.unconfirmed) {
        parameters[ParameterKeyIsConfirmed] = ParameterValueFalse;
    }
    
    if (!self.allowContactsWithNoMessages) {
        parameters[ParameterKeyLastMessageCreatedAt] = ParameterValueGreaterThanZero;
    }
    
    if ([self.labelIds count] > 0) {
        if ([self.labelIds count] > 1) {
            // TODO: Support multiple label searching
            ZNGLogWarn(@"%llu label IDs were provided for contact searching, but the API only supports one.  Gross.  We'll send one.", (unsigned long long)[self.labelIds count]);
        }
        
        parameters[ParameterKeyLabelId] = [self.labelIds firstObject];
    }
    
    if ([self.groupIds count] > 0) {
        if ([self.groupIds count] > 1) {
            // TODO: Support multiple group searching
            ZNGLogWarn(@"%llu group IDs were provided for contact searching, but the API only supports one.  Gross.  We'll send one.", (unsigned long long)[self.groupIds count]);
        }
        
        parameters[ParameterKeyGroupId] = [self.groupIds firstObject];
    }
    
    if (self.unassigned) {
        parameters[ParameterKeyUnassigned] = ParameterValueTrue;
    } else {
        // We only expect one of these two assignment fields to be populated, but there is no need to silently enforce that here.
        if ([self.assignedUserId length] > 0) {
            parameters[ParameterKeyAssignedUserId] = self.assignedUserId;
        }
        
        if ([self.assignedTeamId length] > 0) {
            parameters[ParameterKeyAssignedTeamId] = self.assignedTeamId;
        }
    }
    
    if ([self.searchText length] > 0) {
        if (self.searchMessageBodies) {
           parameters[ParameterKeySearchMessageBodies] = ParameterValueTrue;
        }
        
        parameters[ParameterKeyQuery] = [self.searchText copy];
    }

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

- (void) refreshStartingAtIndex:(NSUInteger)index removingTail:(BOOL)removeTail
{
    // Calculate what page indices should be loaded in order to load some data starting at the specified index.
    
    NSUInteger pageSize = self.pageSize;
    NSMutableIndexSet * pagesToRefresh = [[NSMutableIndexSet alloc] init];
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
    [pagesToRefresh addIndex:lastPageToLoad];
    
    // If the index they requested would load fewer than 10 entries, load an additional page
    NSUInteger remainingCountPastIndexOnPage = pageSize - (index % pageSize);
    
    if (remainingCountPastIndexOnPage < 10) {
        // Ensure that we are not appending an extra page beyond the actual data
        if ((totalPageCount == 0) || ((lastPageToLoad + 1) < totalPageCount)) {
            [pagesToRefresh addIndex:lastPageToLoad + 1];
        }
    }
    
    // Do we need to load any data leading up to this data?  (e.g. They requested object #25 but we have only loaded the first 10 objects.  Since our data is held in an
    //  array, we need the missing values first.)
    if (index > loadedCount) {
        NSUInteger firstPageToLoad = (loadedCount / pageSize) + 1;
        [pagesToRefresh addIndexesInRange:NSMakeRange(firstPageToLoad, lastPageToLoad - 1)];
    }
    
    // Remove any pages that are already loading
    [pagesToRefresh removeIndexes:loadingPages];
    
    if ([pagesToRefresh count] == 0) {
        // Nothing to refresh
        ZNGLogInfo(@"Refresh was called to start with index of %ld, but there is no additional data available (%ld total items, %llu pages loading already).",
                   (unsigned long)index, (unsigned long)totalPageCount, (unsigned long long)[loadingPages count]);
        return;
    }
    
    [self fetchPages:pagesToRefresh removingTail:removeTail];
}

- (BOOL) alreadyLoadingDataAtIndex:(NSUInteger)index
{
    if (!self.loading) {
        // We're not loading anything at all, silly.
        return NO;
    }
    
    NSUInteger page = (index / self.pageSize) + 1;
    return [loadingPages containsIndex:page];
}

- (void) fetchPages:(NSIndexSet *)pages removingTail:(BOOL)removeTail
{
    self.loading = YES;
    NSMutableIndexSet * mutableLoadingPages = [loadingPages mutableCopy];
    [mutableLoadingPages addIndexes:pages];
    loadingPages = mutableLoadingPages;
    
    __weak ZNGInboxDataSet * weakSelf = self;
    __weak ZNGContactClient * weakContactClient = self.contactClient;
    
    // Create an NSBlockOperation for each page to fetch.  Feed them into the fetchQueue so that they will run one at a time in order.
    // Using NSBlockOperation also allows proper cancellation if we are deallocated.  This is a very real concern, especially when doing
    //  filtering based on a live-typed search term.  (We can expect many ZNGInboxDataSearch objects to be created and destroyed as the
    //  user types.)
    [pages enumerateIndexesUsingBlock:^(NSUInteger page, BOOL * _Nonnull stop) {
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
            parameters[ParameterKeyPageIndex] = @(page);
            
            ZNGLogInfo(@"%@ (%p) is loading page #%llu/%llu of data...", [weakSelf class], weakSelf, (unsigned long long)page, (unsigned long long)self.totalPageCount);
            
            [strongContactClient contactListWithParameters:parameters success:^(NSArray<ZNGContact *> *contacts, ZNGStatus *status) {
                weakSelf.totalPageCount = status.totalPages;
                weakSelf.count = status.totalRecords;
                
                // Add a contact client link to all contacts
                for (ZNGContact * contact in contacts) {
                    contact.contactClient = strongContactClient;
                }
                
                if (!(operation.cancelled)) {
                    [self _removeLoadingPage:page];
                    [weakSelf mergeNewData:contacts withStatus:status];
                }
                dispatch_semaphore_signal(semaphore);
            } failure:^(ZNGError *error) {
                ZNGLogWarn(@"Unable to fetch inbox data for page %llu: %@", (unsigned long long)page, error);
                [self _removeLoadingPage:page];
                dispatch_semaphore_signal(semaphore);
            }];
            
            dispatch_time_t thirtySecondTimeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC));
            dispatch_semaphore_wait(semaphore, thirtySecondTimeout);
        }];
        
        [self->fetchQueue addOperation:operation];
    }];
    
    // Remove any data past this current refresh if appropriate
    if (removeTail) {
        __block NSBlockOperation * removeTailOperation = [NSBlockOperation blockOperationWithBlock:^{
            if (removeTailOperation.cancelled) {
                return;
            }
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSUInteger indexAfterCurrentData = [pages lastIndex] * weakSelf.pageSize;
                
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

- (void) _removeLoadingPage:(NSUInteger)page
{
    NSMutableIndexSet * mutableLoadingPages = [loadingPages mutableCopy];
    [mutableLoadingPages removeIndex:page];
    loadingPages = mutableLoadingPages;
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
        NSRange overlapRangeInTotalData = NSMakeRange(startIndex, overlapFinalIndex - startIndex);
        
        NSInteger overflowCount = [incomingContacts count] - overlapRangeInTotalData.length;
        NSArray * replacements = incomingContacts;

        if (overflowCount > 0) {
            replacements = [replacements subarrayWithRange:NSMakeRange(0, overlapRangeInTotalData.length)];
        }
        
        ZNGLogVerbose(@"We received %ld contacts, %ld of which extend past our current data.", (unsigned long)[incomingContacts count], (long)overflowCount);
        
        // We have two very specific simple cases that result from refreshes.
        //  1) Some data disappeared
        //  1) One message has moved to the head
        //  2) All messages are still in order, but one (almost always one) or more needs to be refreshed
        BOOL simpleReorderingOrRefresh = NO;
        if (overflowCount == 0) {
            
            if ((status.totalRecords < self.pageSize) && ([incomingContacts count] < [mutableContacts count])) {
                // We lost someone
                NSMutableIndexSet * removedIndexes = [[NSMutableIndexSet alloc] init];
                
                [mutableContacts enumerateObjectsUsingBlock:^(ZNGContact * _Nonnull contact, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (![incomingContacts containsObject:contact]) {
                        [removedIndexes addIndex:idx];
                    }
                }];
                
                if ([removedIndexes count] == 0) {
                    ZNGLogWarn(@"Our incoming data shows %llu contacts vs. our %llu, but we were unable to find which contacts have disappeared.  Logic no longer applies.",
                               (unsigned long long)[incomingContacts count], (unsigned long long)[mutableContacts count]);
                } else {
                    [mutableContacts removeObjectsAtIndexes:removedIndexes];
                }
            } else if ([incomingContacts count] >= 2) {
                NSArray<ZNGContact *> * oldPage = [[mutableContacts array] subarrayWithRange:overlapRangeInTotalData];
                
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
                            
                            ZingleAccountSession * session = (ZingleAccountSession *)self.contactClient.session;
                            
                            if ([session isKindOfClass:[ZingleAccountSession class]]) {
                                [session contactChanged:newContact];
                            }
                            
                        } else {
                            ZNGLogVerbose(@"Failing to replace %@ since the updated at timestamp has not changed.", [contact fullName]);
                        }
                    }];
                }
            }
        }
        
        if (!simpleReorderingOrRefresh) {
            // Sanity check
            if ((overlapRangeInTotalData.location + overlapRangeInTotalData.length) > [mutableContacts count]) {
                ZNGLogWarn(@"New inbox data overlap range is out of bounds.  Help.  Refreshing all data.");
                [self refresh];
                return;
            }
            
            // Replace the overlapping objects
            NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:overlapRangeInTotalData];
            [mutableContacts replaceObjectsAtIndexes:indexSet withObjects:replacements];
            
            // Append any extra
            if (overflowCount > 0) {
                NSRange overflowRangeInIncomingData = NSMakeRange(overlapRangeInTotalData.length, [incomingContacts count] - overlapRangeInTotalData.length);
                NSArray * overflow = [incomingContacts subarrayWithRange:overflowRangeInIncomingData];
                NSRange appendRange = NSMakeRange([mutableContacts count], [overflow count]);
                NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:appendRange];
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
    if ((self.openStatus == ZNGInboxDataSetOpenStatusOpen) && (contact.isClosed)) {
        return NO;
    }
    
    if ((self.openStatus == ZNGInboxDataSetOpenStatusClosed) && (!contact.isClosed)) {
        return NO;
    }
    
    if ((self.unconfirmed) && (contact.isConfirmed)) {
        return NO;
    }
    
    if ([self.labelIds count] > 0) {
        __block BOOL matchingLabelFound = NO;
        
        [contact.labels enumerateObjectsUsingBlock:^(ZNGLabel * _Nonnull contactLabel, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([self.labelIds containsObject:contactLabel.labelId]) {
                matchingLabelFound = YES;
                *stop = YES;
            }
        }];
        
        if (!matchingLabelFound) {
            return NO;
        }
    }
    
    if ([self.groupIds count] > 0) {
        // TODO: Support groups
    }
    
    // It is unlikely that search text needs an accurate result here.  Take a shot just in case.
    if ([self.searchText length] > 0) {
        NSMutableString * allSearchableFields = [[contact fullName] mutableCopy];
        
        for (ZNGLabel * label in contact.labels) {
            if (label.displayName != nil) {
                [allSearchableFields appendString:label.displayName];
            }
        }
        
        // One message body is better than none, right?
        if ((self.searchMessageBodies) && (contact.lastMessage.body != nil)) {
            [allSearchableFields appendString:contact.lastMessage.body];
        }
        
        if (![[allSearchableFields lowercaseString] containsString:[self.searchText lowercaseString]]) {
            return NO;
        }
    }
    
    return YES;
}

@end
