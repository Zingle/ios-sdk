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

@property (nonatomic, readonly, nonnull) NSString * serviceId;

- (nonnull instancetype) initWithSession:(ZingleSession * _Nonnull __weak)session serviceId:(nonnull NSString *)serviceId;

- (instancetype) initWithSession:(__weak ZingleSession *)session NS_UNAVAILABLE;

@end
