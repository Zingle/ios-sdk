//
//  ZNGDemoViewController.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import "NSString+ZNGMessages.h"

@implementation NSString (ZNGMessages)

- (NSString *)zng_stringByTrimingWhitespace
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
