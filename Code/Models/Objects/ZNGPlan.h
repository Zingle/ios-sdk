//
//  ZNGPlan.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZingleModel.h"

@class ZNGAccount;
@class ZNGService;

@interface ZNGPlan : ZingleModel

@property (nonatomic, retain) NSString *code, *displayName;
@property (nonatomic) BOOL isPrinterPlan;
@property (nonatomic, retain) NSNumber *monthlyOrUnitPrice, *setupPrice, *termMonths;

- (id)initWithAccount:(ZNGAccount *)account;
- (ZNGService *)newService;

@end
