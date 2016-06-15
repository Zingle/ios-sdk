//
//  ZNGBaseClientService.h
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZNGBaseClientAccount.h"

@class ZNGService;

/*
 *  A Zingle SDK client that requires both an active account and service
 */
@interface ZNGBaseClientService : ZNGBaseClientAccount

@property (nonatomic, readonly, nonnull) ZNGService * service;

- (nonnull instancetype) initWithSession:(ZingleSession * _Nonnull __weak)session account:(nonnull ZNGAccount *)account service:(nonnull ZNGService *)service;

@end
