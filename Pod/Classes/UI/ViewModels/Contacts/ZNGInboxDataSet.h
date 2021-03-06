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
@class ZNGContactDataSetBuilder;

typedef enum {
    ZNGInboxDataSetOpenStatusOpen = 0,
    ZNGInboxDataSetOpenStatusClosed,
    ZNGInboxDataSetOpenStatusBoth
} ZNGInboxDataSetOpenStatus;

extern NSString * _Nonnull const ZNGInboxDataSetSortFieldContactCreatedAt;
extern NSString * _Nonnull const ZNGInboxDataSetSortFieldLastMessageCreatedAt;
extern NSString * _Nonnull const ZNGInboxDataSetSortFieldUnconfirmedAt;
extern NSString * _Nonnull const ZNGInboxDataSetSortFieldLastName;
extern NSString * _Nonnull const ZNGInboxDataSetSortDirectionAscending;
extern NSString * _Nonnull const ZNGInboxDataSetSortDirectionDescending;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Provides paginated data to be used by a UITableView.  Supports KVO on all properties.
 *
 *  Subclasses should be made of this class to provide more specific filtering.
 */
@interface ZNGInboxDataSet : NSObject

#pragma mark - Status and results
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
 *  Page size!
 */
@property (nonatomic, readonly) NSUInteger pageSize;

/**
 *  A human-readable title for the current filter set.
 */
@property (nonatomic, readonly, nonnull) NSString * title;

/**
 *  All contacts matching this filter that have been successfully fetched.
 */
@property (nonatomic, readonly, nonnull) NSOrderedSet<ZNGContact *> * contacts;

#pragma mark - Configuration properties
/**
 *  Readonly properties that determine the filtering done by this inbox data set.
 *  These are set on initialization, usually by a ZNGInboxDataSetBuilder object.
 */

/**
 *  Whether to show contacts with open conversations only, closed only, or both.
 */
@property (nonatomic, readonly) ZNGInboxDataSetOpenStatus openStatus;

/**
 *  Show only unconfirmed contacts.  If this is not set, all contacts, both confirmed and unconfirmed, will be included.
 */
@property (nonatomic, readonly) BOOL unconfirmed;

/**
 *  If this flag is set, matching contacts will be returned even if there is no message history.
 */
@property (nonatomic, readonly) BOOL allowContactsWithNoMessages;

/**
 *  The fields (by name for some stock options or UUID for any date/datetime contact field) used to sort contacts.
 *  May include "asc" or "desc" after a space to define order.
 *  e.g. "last_name asc", "created_at desc", "264da6d4-f555-4e35-bf86-c42f8dc47357 asc"
 *
 *  Defaults to ["last_message_created_at desc"]
 */
@property (nonatomic, readonly, nonnull) NSArray<NSString *> * sortFields;

/**
 *  Array of label IDs used to filter contacts.
 */
@property (nonatomic, readonly, nullable) NSArray<NSString *> * labelIds;

/**
 *  Array of group IDs used to filter contacts.
 */
@property (nonatomic, readonly, nullable) NSArray<NSString *> * groupIds;

/**
 *  If this flag is set, only unassigned conversations will be returned.
 */
@property (nonatomic, readonly) BOOL unassigned;

/**
 *  The team ID to which all returned contacts are assigned
 */
@property (nonatomic, readonly, nullable) NSString * assignedTeamId;

/**
 *  The user ID to which all returned contacts are assigned.
 */
@property (nonatomic, readonly, nullable) NSString * assignedUserId;

/**
 *  When this user ID is set, matching contacts will either be assigned to this specific user or to a team
 *   to which this user belongs.
 *
 *  Behavior is undefined if this is set in addition to either assignedTeamId or assignedUserId.
 */
@property (nonatomic, readonly, nullable) NSString * assignedRelevantToUserId;

/**
 *  Search text.  searchMessageBodies determines whether this searches only contact fields or also message contents to/from that contact.
 */
@property (nonatomic, readonly, nullable) NSString * searchText;

/**
 *  Should searchText search message bodies to/from this contact in addition to contact fields?  Defaults to NO.
 */
@property (nonatomic, readonly) BOOL searchMessageBodies;

#pragma mark -

@property (nonatomic, strong, nonnull) ZNGContactClient * contactClient;

#pragma mark - Initialization
/**
 *  Convenience constructor that provides a builder object and automatically calls build using it.
 */
+ (nonnull instancetype) dataSetWithBlock:(__attribute__((noescape)) void (^ _Nonnull)(ZNGContactDataSetBuilder * builder))builderBlock;

- (nonnull instancetype) initWithBuilder:(ZNGContactDataSetBuilder *)builder;

#pragma mark - Saving

/**
 *  A contact data set builder that can be serialized to save the current inbox type.
 */
- (ZNGContactDataSetBuilder *) builder;

#pragma mark - Comparison

/**
 *  Tests whether two data sets are equal when ignoring open/closed status.
 */
- (BOOL) isEqualDisregardingOpenStatus:(ZNGInboxDataSet *)object;

#pragma mark - Actions
/**
 *  Refreshes the first page of data.  This data will be merged into the contacts array without resetting the loadingInitialData property.
 */
- (void) refresh;

/**
 *  Returns YES if there is a fetch operation in progress for the specificed index.  Returns NO if `loading` is NO.
 */
- (BOOL) alreadyLoadingDataAtIndex:(NSUInteger)index;

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

#pragma mark - Local contact filtering
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

NS_ASSUME_NONNULL_END

@end
