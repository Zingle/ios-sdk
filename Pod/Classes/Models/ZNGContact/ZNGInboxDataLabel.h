//
//  ZNGInboxDataLabel.h
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataSet.h"

@interface ZNGInboxDataLabel : ZNGInboxDataSet

/**
 * Designated initializer.
 *
 * @param theServiceId The service identifier string for the user's current service.
 * @param labelId The label identifier to be used for filtering.
 */
- (id) initWithServiceId:(NSString *)theServiceId labelId:(NSString *)labelId;

@end
