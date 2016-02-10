//
//  ZingleValueTransformers.m
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import "ZingleValueTransformers.h"
#import <Mantle/Mantle.h>

@implementation ZingleValueTransformers

+ (NSValueTransformer *)dateValueTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSNumber *dateValue, BOOL *success, NSError *__autoreleasing *error) {
        return [NSDate dateWithTimeIntervalSince1970:[dateValue doubleValue]];
    } reverseBlock:^id(NSDate *date, BOOL *success, NSError *__autoreleasing *error) {
        return [NSNumber numberWithDouble:[date timeIntervalSince1970]];
    }];
}

@end
