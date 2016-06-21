//
//  ZNGBaseClientService.h
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZNGBaseClientAccount.h"

/**
 *  A Zingle SDK client that requires both an active account and service
 */
@interface ZNGBaseClientService : ZNGBaseClientAccount

@property (nonatomic, readonly, nonnull) NSString * serviceId;

- (nonnull instancetype) initWithSession:(ZingleSession * _Nonnull __weak)session account:(nonnull ZNGAccount *)account serviceId:(nonnull NSString *)serviceId;

@end
