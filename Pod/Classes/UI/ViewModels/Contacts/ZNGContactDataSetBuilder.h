//
//  ZNGContactDataSetBuilder.h
//  Pods
//
//  Created by Jason Neel on 4/25/17.
//
//

#import <Foundation/Foundation.h>

@class ZNGContactClient;
@class ZNGInboxDataSet;

@interface ZNGContactDataSetBuilder : NSObject

/**
 *  A previously existing data set used to begin building a new one.
 *  This is often used to create a search text data set from a non-search data set.
 *  It can also be used to chain together several live searches as a user types more text.
 *
 *  Setting this property will overwrite all other properties in this builder.
 */
@property (nonatomic, strong, nullable) ZNGInboxDataSet * baseDataSet;

/**
 *  Closed or open conversations (can never be both simultaneously)
 */
@property (nonatomic, assign) BOOL closed;

/**
 *  Show only unconfirmed contacts.  If this is not set, all contacts, both confirmed and unconfirmed, will be included.
 */
@property (nonatomic, assign) BOOL unconfirmed;

/**
 *  If this flag is set, matching contacts will be returned even if there is no message history.
 */
@property (nonatomic, assign) BOOL allowContactsWithNoMessages;

/**
 *  Array of label IDs used to filter contacts.
 */
@property (nonatomic, copy, nullable) NSArray<NSString *> * labelIds;

/**
 *  Array of group IDs used to filter contacts.
 */
@property (nonatomic, copy, nullable) NSArray<NSString *> * groupIds;

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

@end
