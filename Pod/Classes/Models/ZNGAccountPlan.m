//
//  ZNGAccountPlan.m
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import "ZNGAccountPlan.h"

@implementation ZNGAccountPlan

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"planId" : @"id",
             @"code" : @"code",
             @"monthlyOrUnitPrice" : @"monthly_or_unit_price",
             @"termMonths" : @"term_months",
             @"setupPrice" : @"setup_price",
             @"displayName" : @"display_name",
             @"isPrinterPlan" : @"is_printer_plan"
             };
}

@end
