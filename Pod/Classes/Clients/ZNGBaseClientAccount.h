//
//  ZNGBaseClientAccount.h
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZNGBaseClient.h"

@class ZNGAccount;

/*
 *  A Zingle SDK client that must be initiazed with an account
 */
@interface ZNGBaseClientAccount : ZNGBaseClient

@property (nonatomic, readonly, nonnull) ZNGAccount * account;

- (instancetype) initWithAccount:(ZNGAccount *)account;

@end
