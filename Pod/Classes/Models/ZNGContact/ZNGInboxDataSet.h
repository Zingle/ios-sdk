//
//  ZNGInboxDataSet.h
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import <Foundation/Foundation.h>
@class ZNGContact;
@class ZNGContactClient;

extern NSString * __nonnull const ParameterKeyPageIndex;
extern NSString * __nonnull const ParameterKeyPageSize;
extern NSString * __nonnull const ParameterKeySortField;
extern NSString * __nonnull const ParameterKeySortDirection;
extern NSString * __nonnull const ParameterKeyLastMessageCreatedAt;
extern NSString * __nonnull const ParameterKeyIsConfirmed;
extern NSString * __nonnull const ParameterKeyIsClosed;
extern NSString * __nonnull const ParameterKeyLabelId;
extern NSString * __nonnull const ParameterKeyQuery;
extern NSString * __nonnull const ParameterKeyIsStarred;
extern NSString * __nonnull const ParameterKeySearchMessageBodies;

extern NSString * __nonnull const ParameterValueTrue;
extern NSString * __nonnull const ParameterValueFalse;
extern NSString * __nonnull const ParameterValueGreaterThanZero;
extern NSString * __nonnull const ParameterValueDescending;
extern NSString * __nonnull const ParameterValueLastMessageCreatedAt;

/**
 *  Provides paginated data to be used by a UITableView.  Supports KVO on all properties.
 *
 *  Subclasses should be made of this class to provide more specific filtering.
 */
@interface ZNGInboxDataSet : NSObject

/**
 *  Initially set to YES until the first set of paginated data arrives, allowing us to set the count value.
 */
@property (nonatomic, readonly) BOOL loadingInitialData;

/**
 *  Toggled every time new requests are pending after a refresh call.
 */
@property (nonatomic, readonly) BOOL loading;

/**
 *  Once we have received our first piece of data, this contains the amount of total data available (but not necessarily
 *  yet retrieved.)
 *
 *  This varies from [contacts count] in that [contacts count] only returns the number of entries actually downloaded and fully available.
 */
@property (nonatomic, readonly) NSUInteger count;

/**
 *  All contacts matching this filter that have been successfully fetched.
 */
@property (nonatomic, readonly, nonnull) NSOrderedSet<ZNGContact *> * contacts;

/**
 *  Designated initializer.
 *
 * @param theServiceId The service identifier string for the user's current service.
 */
- (nonnull instancetype) initWithContactClient:(nonnull ZNGContactClient *)contactClient;

/**
 *  Refreshes the first page of data.  This data will be merged into the contacts array without resetting the loadingInitialData property.
 */
- (void) refresh;

/**
 *  Refreshes data starting around the current value.  This data will be merged into the contacts array if possible.  Any data trailing past the data fetched
 *   by this request will be discarded.  (e.g. If we refresh and that ends up retrieving page 4 of 10, any page 5 or later will be discarded until it is fetched
 *   again in the future.)
 *
 *  @param index The index at which to refresh.  If there is unloaded data before this point, it will be fetched as well.
 *
 *  @note If this data lies beyond the current range of loaded data, all missing data leading up to this value will be loaded first.
 */
- (void) refreshStartingAtIndex:(NSUInteger)index removingTail:(BOOL)removeTail;

/**
 *  Overridden by subclasses to effect filtering.
 *
 *  It is recommended that subclasses call [super parameters] to start building their own.
 *
 *  These default parameters include page size and sort order. 
 */
- (nonnull NSMutableDictionary *) parameters;

/**
 *  Notify this data set of a local change that has not yet propogated from the server.  If a call to contactBelongsInDataSet: for this contact returns NO, that contact
 *   will be excluded from this data set (until the next remote update.)
 */
- (void) contactWasChangedLocally:(nonnull ZNGContact *)contact;

/**
 *  This method will attempt to predict whether a contact object belongs in this data set.  It can be used to predict whether a contact will be removed
 *   when a change is sent to the server.
 */
- (BOOL) contactBelongsInDataSet:(nonnull ZNGContact *)contact;

@end
