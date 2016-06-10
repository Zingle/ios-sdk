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

NSString * const ParameterValueTrue                 = @"true";
NSString * const ParameterValueFalse                = @"false";
NSString * const ParameterValueGreaterThanZero      = @"greater_than(0)";
NSString * const ParameterValueDescending           = @"desc";
NSString * const ParameterValueLastMessageCreatedAt = @"last_message_created_at";

@implementation ZNGInboxDataSet
{
    NSString * serviceId;
    NSUInteger pageSize;
    NSUInteger totalPageCount;
}

- (id) initWithServiceId:(NSString *)theServiceId
{
    self = [super init];
    
    if (self != nil) {
        serviceId = theServiceId;
        _loading = YES;
        _contacts = @[];
        pageSize = 10;  // TODO: Raise this value after initial testing to at least 20 or 25.
        [self refresh];
    }
    
    return self;
}

#pragma mark - Filtering
- (NSMutableDictionary *) parameters
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
    NSMutableArray<NSNumber *> * pagesToRefresh = [[NSMutableArray alloc] init];
    NSUInteger loadedCount = [_contacts count];
    NSUInteger lastPageToLoad = (index / pageSize);
    
    // If the index they requested is more than 50% through its page, we will load one more
    NSUInteger remainingCountPastIndexOnPage = pageSize - (index % pageSize);
    
    if (remainingCountPastIndexOnPage < (pageSize / 2)) {
        lastPageToLoad++;
    }
    
    // Make sure we do not request an empty page
    if (lastPageToLoad > totalPageCount) {
        lastPageToLoad = totalPageCount;
    }
    
    // Build our list of page indices
    if (index > (loadedCount + 1)) {
        NSUInteger firstPageToLoad = (loadedCount / pageSize);
        
        for (NSUInteger i = firstPageToLoad; i < lastPageToLoad; i++) {
            [pagesToRefresh addObject:@(i)];
        }
    }
    
    if ([pagesToRefresh count] == 0) {
        // Nothing to refresh
        ZNGLogInfo(@"Refresh was called to start with index of %ld, but there is no additional data available (%ld total items.)", (unsigned long)index, (unsigned long)totalPageCount);
        return;
    }
    
    [self fetchPages:pagesToRefresh];
}

- (void) fetchPages:(NSArray<NSNumber *> *)pages
{
    for (NSNumber * pageNumber in pages) {
        NSMutableDictionary * parameters = [self parameters];
        parameters[ParameterKeyPageIndex] = pageNumber;
        
        [ZNGContactClient contactListWithServiceId:serviceId parameters:parameters success:^(NSArray *contacts, ZNGStatus *status) {
            totalPageCount = status.totalPages;
            _count = status.totalRecords;
            
            [self mergeNewData:contacts withStatus:status];
        } failure:^(ZNGError *error) {
            ZNGLogWarn(@"Unable to fetch inbox data for page %@: %@", pageNumber, error);
        }];
    }
}

- (void) mergeNewData:(NSArray<ZNGContact *> *)incomingContacts withStatus:(ZNGStatus *)status
{
    if (![[NSThread currentThread] isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self mergeNewData:incomingContacts withStatus:status];
        });
        return;
    }
    
    // Grab our mutable proxy object
    NSMutableArray<ZNGContact *> * mutableContacts = [self mutableArrayValueForKey:NSStringFromSelector(@selector(contacts))];
    
    NSUInteger oldDataCount = [mutableContacts count];
    NSUInteger startIndex = status.page * status.pageSize;
    
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
        NSRange overlapRange = NSMakeRange(startIndex, MIN(oldDataCount, startIndex + [incomingContacts count]));
        
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
}

@end
