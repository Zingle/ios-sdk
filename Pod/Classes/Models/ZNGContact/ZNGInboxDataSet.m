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

NSString * const ParameterValueTrue                 = @"true";
NSString * const ParameterValueFalse                = @"false";
NSString * const ParameterValueGreaterThanZero      = @"greater_than(0)";
NSString * const ParameterValueDescending           = @"desc";
NSString * const ParameterValueLastMessageCreatedAt = @"last_message_created_at";

@interface ZNGInboxDataSet ()
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong, nonnull) NSArray<ZNGContact *> * contacts;
@end

@implementation ZNGInboxDataSet
{
    NSString * serviceId;
    NSUInteger pageSize;
    NSUInteger totalPageCount;
    
    dispatch_queue_t fetchingQueue;
}

- (nonnull instancetype) initWithServiceId:(nonnull NSString *)theServiceId
{
    self = [super init];
    
    if (self != nil) {
        fetchingQueue = dispatch_queue_create("com.zingle.sdk.contact.fetching", NULL);
        
        serviceId = theServiceId;
        self.loading = YES;
        _contacts = @[];
        pageSize = 10;  // TODO: Raise this value after initial testing to at least 20 or 25.
        [self refresh];
    }
    
    return self;
}

#pragma mark - Filtering
- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [[NSMutableDictionary alloc] init];
    parameters[ParameterKeyPageSize] = @(pageSize);
    parameters[ParameterKeySortField] = ParameterValueLastMessageCreatedAt;
    parameters[ParameterKeySortDirection] = ParameterValueDescending;
    parameters[ParameterKeyLastMessageCreatedAt] = ParameterValueGreaterThanZero;

    return parameters;
}

#pragma mark - Loading data
- (void) refresh
{
    [self refreshStartingAtIndex:0];
}

- (void) refreshStartingAtIndex:(NSUInteger)index
{
    NSMutableOrderedSet<NSNumber *> * pagesToRefresh = [[NSMutableOrderedSet alloc] init];
    NSUInteger loadedCount = [_contacts count];
    NSUInteger lastPageToLoad = (index / pageSize) + 1;
    
    [pagesToRefresh addObject:@(lastPageToLoad)];
    
    // If the index they requested would load fewer than 10 entries, load an additional page
    NSUInteger remainingCountPastIndexOnPage = pageSize - (index % pageSize);
    
    if (remainingCountPastIndexOnPage < 10) {
        [pagesToRefresh addObject:@(lastPageToLoad + 1)];
    }
    
    // Do we need to load any data leading up to this data?
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
    
    [self fetchPages:[pagesToRefresh array]];
}

- (void) fetchPages:(NSArray<NSNumber *> *)pages
{
    dispatch_async(fetchingQueue, ^{
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        for (NSNumber * pageNumber in pages) {
            NSMutableDictionary * parameters = [self parameters];
            parameters[ParameterKeyPageIndex] = pageNumber;
            
            [ZNGContactClient contactListWithServiceId:serviceId parameters:parameters success:^(NSArray *contacts, ZNGStatus *status) {
                totalPageCount = status.totalPages;
                _count = status.totalRecords;
                
                [self mergeNewData:contacts withStatus:status];
                dispatch_semaphore_signal(semaphore);
            } failure:^(ZNGError *error) {
                ZNGLogWarn(@"Unable to fetch inbox data for page %@: %@", pageNumber, error);
                dispatch_semaphore_signal(semaphore);
            }];
            
            dispatch_time_t thirtySecondTimeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC));
            dispatch_semaphore_wait(semaphore, thirtySecondTimeout);
        }
    });
}

- (void) mergeNewData:(NSArray<ZNGContact *> *)incomingContacts withStatus:(ZNGStatus *)status
{
    if (![[NSThread currentThread] isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self mergeNewData:incomingContacts withStatus:status];
        });
        return;
    }
    
    // Grab our mutable proxy object
    NSMutableArray<ZNGContact *> * mutableContacts = [self mutableArrayValueForKey:NSStringFromSelector(@selector(contacts))];
    
    NSUInteger oldDataCount = [mutableContacts count];
    NSUInteger startIndex = (status.page - 1) * status.pageSize;
    
    // Check for the most simple and common case: We have brand new data to append.
    if (startIndex >= [self.contacts count]) {
        // Sanity check
        if (startIndex > [self.contacts count]) {
            ZNGLogWarn(@"Incoming data starts at index %ld, but we only have %ld items in our current data.  Appending anyway (at incorrect indices.)", (unsigned long)startIndex, (unsigned long)oldDataCount);
        }
        
        // Append all of the objects
        [mutableContacts addObjectsFromArray:incomingContacts];
    } else {
        // We have some overlap between our current data and this data.
        NSUInteger overlapFinalIndex = MIN(oldDataCount - 1, startIndex + [incomingContacts count]);
        NSRange overlapRange = NSMakeRange(startIndex, overlapFinalIndex - startIndex);
        
        // Replace the overlapping objects
        [mutableContacts replaceObjectsInRange:overlapRange withObjectsFromArray:incomingContacts];
        
        // Append any extra
        NSInteger overflowCount = [incomingContacts count] - overlapRange.length;
        
        if (overflowCount > 0) {
            NSRange overflowRange = NSMakeRange(overlapRange.length, [incomingContacts count] - overlapRange.length);
            NSArray * overflow = [incomingContacts subarrayWithRange:overflowRange];
            [mutableContacts addObjectsFromArray:overflow];
        }
    }
    
    self.loading = NO;
    self.count = status.totalRecords;
    totalPageCount = status.totalPages;
}

@end
