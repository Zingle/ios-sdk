//
//  ZingleAccountSession.h
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZingleSession.h"

@class ZNGService;
@class ZNGAccount;

@interface ZingleAccountSession : ZingleSession

@property (nonatomic, readonly, nullable) NSArray<ZNGAccount *> * availableAccounts;
@property (nonatomic, readonly, nullable) NSArray<ZNGService *> * availableServices;

@property (nonatomic, strong, nullable) ZNGAccount * account;
@property (nonatomic, strong, nullable) ZNGService * service;

@end
