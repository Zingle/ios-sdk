//
//  ZNGInboxDataSearch.h
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataSet.h"

@interface ZNGInboxDataSearch : ZNGInboxDataSet

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, readonly) NSString * searchTerm;

/**
 *  If this inbox data property is set, searching will occur within this data set
 */
@property (nonatomic, strong) ZNGInboxDataSet * targetInbox;

/**
 *  Whether the search term should also match message bodies.  Defaults to NO.
 */
@property (nonatomic, assign) BOOL searchMessageBodies;

/**
 *  If this flag is set, results will be limited to those with messages.  Defaults to YES.
 */
@property (nonatomic, assign) BOOL onlyContactsWithMessages;

/**
 * Designated initializer.
 *
 * @param theServiceId The service identifier string for the user's current service.
 * @param theSearchTerm The search term to be sent to the server for filtering.  See https://github.com/Zingle/rest-api-documentation/blob/master/contacts/GET_list.md
 */
- (instancetype) initWithContactClient:(ZNGContactClient *)contactClient searchTerm:(NSString *)theSearchTerm targetInboxData:(ZNGInboxDataSet * __nullable)targetInbox;

- (instancetype) initWithContactClient:(ZNGContactClient *)contactClient NS_UNAVAILABLE;

NS_ASSUME_NONNULL_END

@end
