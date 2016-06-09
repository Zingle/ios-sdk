//
//  ZNGInboxDataSet.h
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import <Foundation/Foundation.h>
@class ZNGContact;

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
 *  Refreshes the first page of data.  This data will be merged into the contacts array without resetting the loading property.
 */
- (void) refresh;

/**
 *  Refreshes data starting around the current value.  This data will be merged into the contacts array if possible.
 *
 *  @note If this data lies beyond the current range of loaded data, all missing data leading up to this value will be loaded.
 */
- (void) refreshStartingAtIndex:(NSUInteger)index;

@end
