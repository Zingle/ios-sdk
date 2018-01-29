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

+ (NSValueTransformer*)dateValueTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSNumber * dateValue, BOOL *success, NSError *__autoreleasing *error) {
        double dateDouble = [dateValue doubleValue];
        
        if (dateDouble == 0.0)
        {
            return nil;
        }
        
        return [NSDate dateWithTimeIntervalSince1970:dateDouble];
    } reverseBlock:^id(NSDate * date, BOOL *success, NSError *__autoreleasing *error) {
        NSTimeInterval interval = [date timeIntervalSince1970];
        NSInteger time = interval;
        return [NSNumber numberWithInteger:time];
    }];
}

+ (NSValueTransformer *)millisecondDateValueTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSNumber * dateValue, BOOL *success, NSError *__autoreleasing *error) {
        double dateDouble = [dateValue doubleValue] / 1000.0;
        
        if (dateDouble == 0.0)
        {
            return nil;
        }
        
        return [NSDate dateWithTimeIntervalSince1970:dateDouble];
    } reverseBlock:^id(NSDate * date, BOOL *success, NSError *__autoreleasing *error) {
        NSTimeInterval interval = [date timeIntervalSince1970];
        NSInteger time = interval * 1000.0;
        return [NSNumber numberWithInteger:time];
    }];
}

@end
