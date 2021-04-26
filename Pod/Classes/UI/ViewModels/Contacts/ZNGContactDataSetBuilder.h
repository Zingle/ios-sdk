//
//  ZNGContactDataSetBuilder.h
//  Pods
//
//  Created by Jason Neel on 4/25/17.
//
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import "ZNGInboxDataSet.h"

@class ZingleAccountSession;
@class ZNGContactClient;

@interface ZNGContactDataSetBuilder : MTLModel <MTLJSONSerializing>

/**
 *  A previously existing data set used to begin building a new one.
 *  This is often used to create a search text data set from a non-search data set.
 *  It can also be used to chain together several live searches as a user types more text.
 *
 *  Setting this property will overwrite all other properties in this builder.
 */
@property (nonatomic, strong, nullable) ZNGInboxDataSet * baseDataSet;

/**
 *  How many contacts to load in each query.  Defaults to 25.
 */
@property (nonatomic, assign) NSUInteger pageSize;

/**
 *  Whether to show contacts with open conversations only, closed only, or both.
 */
@property (nonatomic, assign) ZNGInboxDataSetOpenStatus openStatus;

/**
 *  Show only unconfirmed contacts.  If this is not set, all contacts, both confirmed and unconfirmed, will be included.
 */
@property (nonatomic, assign) BOOL unconfirmed;

/**
 *  If this flag is set, matching contacts will be returned even if there is no message history.
 */
@property (nonatomic, assign) BOOL allowContactsWithNoMessages;

/**
 *  The fields (by name for some stock options or UUID for any date/datetime contact field) used to sort contacts.
 *  May include "asc" or "desc" after a space to define order.
 *  e.g. "last_name asc", "created_at desc", "264da6d4-f555-4e35-bf86-c42f8dc47357 asc"
 *
 *  Defaults to ["last_message_created_at desc"]
 */
@property (nonatomic, copy, nullable) NSArray<NSString *> * sortFields;

/**
 *  Array of label IDs used to filter contacts.
 */
@property (nonatomic, copy, nullable) NSArray<NSString *> * labelIds;

/**
 *  Array of group IDs used to filter contacts.
 */
@property (nonatomic, copy, nullable) NSArray<NSString *> * groupIds;

/**
 *  If this flag is set, only unassigned conversations will be returned.
 */
@property (nonatomic, assign) BOOL unassigned;

/**
 *  The team ID to which all returned contacts are assigned
 */
@property (nonatomic, copy, nullable) NSString * assignedTeamId;

/**
 *  The user ID to which all returned contacts are assigned.
 */
@property (nonatomic, copy, nullable) NSString * assignedUserId;

/**
 *  When this user ID is set, matching contacts will either be assigned to this specific user or to a team
 *   to which this user belongs.
 *
 *  Behavior is undefined if this is set in addition to either assignedTeamId or assignedUserId.
 */
@property (nonatomic, copy, nullable) NSString * assignedRelevantToUserId;

/**
 * If set to a value other than `ZNGInboxDataSetMentionFilterNone`, allows filtering by unread mentions or all mentions.
 * Defaults to `ZNGInboxDataSetMentionFilterNone`.
 */
@property (nonatomic, assign) ZNGInboxDataSetMentionFilter mentionFilter;

/**
 *  Search text.  searchMessageBodies determines whether this searches only contact fields or also message contents to/from that contact.
 */
@property (nonatomic, copy, nullable) NSString * searchText;

/**
 *  Should searchText search message bodies to/from this contact in addition to contact fields?  Defaults to NO.
 */
@property (nonatomic, assign) BOOL searchMessageBodies;

@property (nonatomic, strong, nonnull) ZNGContactClient * contactClient;

- (nonnull ZNGInboxDataSet *)build;

/**
 *  Confirms that an inbox data set made with this builder can be used with the provided session.
 *  Fails if a group/label/user/team specified in the data set is not present in the provided session.
 */
- (BOOL) canBeUsedForSession:(ZingleAccountSession * _Nonnull)session;

@end
