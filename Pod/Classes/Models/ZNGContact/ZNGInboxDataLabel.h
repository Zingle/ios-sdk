//
//  ZNGInboxDataLabel.h
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataSet.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZNGInboxDataLabel : ZNGInboxDataSet

/**
 * Designated initializer.
 *
 * @param theServiceId The service identifier string for the user's current service.
 * @param labelId The label identifier to be used for filtering.
 */
- (id) initWithContactClient:(ZNGContactClient *)contactClient labelId:(NSString *)labelId;

- (id) initWithContactClient:(ZNGContactClient *)contactClient NS_UNAVAILABLE;

@property (nonatomic, copy, nonnull) NSString * labelId;

NS_ASSUME_NONNULL_END

@end
