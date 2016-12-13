//
//  ZNGPrinter.m
//  Pods
//
//  Created by Jason Neel on 12/12/16.
//
//

#import "ZNGPrinter.h"

@implementation ZNGPrinter

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(printerID)) : @"id",
             NSStringFromSelector(@selector(displayName)) : @"display_name"
             };
}

@end
