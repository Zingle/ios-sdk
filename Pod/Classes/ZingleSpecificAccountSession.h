//
//  ZingleSpecificAccountSession.h
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZingleSession.h"

@class ZNGAccount;
@class ZNGService;

/*
 *  Private subclass of ZingleAccountSession that will always have session and account information available.
 *
 *  Should only be accessed through a ZingleAccountSession object.
 */
@interface ZingleSpecificAccountSession : ZingleSession

@property (nonatomic, readonly, nonnull) ZNGAccount * account;
@property (nonatomic, readonly, nonnull) ZNGService * service;

- (instancetype) initWithToken:(NSString *)token key:(NSString *)key account:(ZNGAccount *)account service:(ZNGService *)service;

@end
