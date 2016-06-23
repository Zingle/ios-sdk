//
//  ZNGInboxDataSearch.h
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataSet.h"

@interface ZNGInboxDataSearch : ZNGInboxDataSet

/**
 * Designated initializer.
 *
 * @param theServiceId The service identifier string for the user's current service.
 * @param theSearchTerm The search term to be sent to the server for filtering.  See https://github.com/Zingle/rest-api-documentation/blob/master/contacts/GET_list.md
 */
- (nonnull instancetype) initWithContactClient:(nonnull ZNGContactClient *)contactClient searchTerm:(nonnull NSString *)theSearchTerm;

- (nonnull instancetype) initWithContactClient:(nonnull ZNGContactClient *)contactClient NS_UNAVAILABLE;

@end
