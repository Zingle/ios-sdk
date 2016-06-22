//
//  ZNGBaseClientService.h
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZNGBaseClient.h"

/**
 *  A Zingle SDK client that requires both an active account and service
 */
@interface ZNGBaseClientService : ZNGBaseClient

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, readonly, nonnull) NSString * serviceId;

- (instancetype) initWithSession:(__weak ZingleSession *)session serviceId:(NSString *)serviceId;

- (instancetype) initWithSession:(__weak ZingleSession *)session NS_UNAVAILABLE;

NS_ASSUME_NONNULL_END

@end
