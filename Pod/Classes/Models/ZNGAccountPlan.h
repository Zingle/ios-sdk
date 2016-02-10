//
//  ZNGAccountPlan.h
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGAccountPlan : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *planId;
@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSNumber *monthlyOrUnitPrice;
@property (nonatomic, strong) NSNumber *termMonths;
@property (nonatomic, strong) NSNumber *setupPrice;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic) bool isPrinterPlan;

@end
