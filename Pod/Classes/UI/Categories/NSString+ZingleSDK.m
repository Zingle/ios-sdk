//
//  ZNGConversationViewController.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import "NSString+ZingleSDK.h"

@implementation NSString (ZingleSDK)

- (NSString *)zng_stringByTrimingWhitespace
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
