//
//  ZNGInboxDataSet.h
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import <Foundation/Foundation.h>
@class ZNGContact;

extern NSString * const ParameterKeyPageIndex;
extern NSString * const ParameterKeyPageSize;
extern NSString * const ParameterKeySortField;             
extern NSString * const ParameterKeySortDirection;         
extern NSString * const ParameterKeyLastMessageCreatedAt;  
extern NSString * const ParameterKeyIsConfirmed;           
extern NSString * const ParameterKeyIsClosed;              
extern NSString * const ParameterKeyLabelId;               
extern NSString * const ParameterKeyQuery;
extern NSString * const ParameterKeyIsStarred;

extern NSString * const ParameterValueTrue;                
extern NSString * const ParameterValueFalse;               
extern NSString * const ParameterValueGreaterThanZero;     
extern NSString * const ParameterValueDescending;          
extern NSString * const ParameterValueLastMessageCreatedAt;

/**
 *  Provides paginated data to be used by a UITableView.  Supports KVO on all properties.
 *
 *  Subclasses should be made of this class to provide more specific filtering.
 */
@interface ZNGInboxDataSet : NSObject

/**
 *  Initially set to YES until the first set of paginated data arrives, allowing us to set the count value.
 */
@property (nonatomic, readonly) BOOL loading;

/**
 *  Once we have received our first piece of data, this contains the amount of total data available (but not necessarily
 *  yet retrieved.)
 */
@property (nonatomic, readonly) NSUInteger count;

/**
 *  All contacts matching this filter that have been successfully fetched.
 */
@property (nonatomic, readonly, nonnull) NSArray<ZNGContact *> * contacts;

/**
 *  Designated initializer.
 *
 * @param theServiceId The service identifier string for the user's current service.
 */
- (id) initWithServiceId:(NSString *)theServiceId;

/**
 *  Refreshes the first page of data.  This data will be merged into the contacts array without resetting the loading property.
 */
- (void) refresh;

/**
 *  Refreshes data starting around the current value.  This data will be merged into the contacts array if possible.
 *
 *  @note If this data lies beyond the current range of loaded data, all missing data leading up to this value will be loaded.
 */
- (void) refreshStartingAtIndex:(NSUInteger)index;

/**
 *  Overridden by subclasses to effect filtering.
 *
 *  It is recommended that subclasses call this implementation of parameters to start building their own.
 *
 *  These default parameters include page size and sort order. 
 */
- (NSMutableDictionary *) parameters;

@end
