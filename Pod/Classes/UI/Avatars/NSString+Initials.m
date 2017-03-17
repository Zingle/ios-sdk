//
//  NSString+Initials.m
//  Pods
//
//  Created by Jason Neel on 3/17/17.
//
//

#import "NSString+Initials.h"

@implementation NSString (Initials)

- (NSString *)initials
{
    // If we have fewer than three characters, we can safely return the entire name.  This solves the case of an emoji for free.
    if ([self length] <= 2) {
        return self;
    }
    
    NSArray<NSString *> * names = [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSMutableString * initials = [[NSMutableString alloc] initWithCapacity:3];
    
    for (NSString * name in names) {
        if ([name length] > 0) {
            [initials appendFormat:@"%c", [[name uppercaseString] characterAtIndex:0]];
        }
    }
    
    if ([initials length] == 0) {
        return @"";
    }
    
    return initials;
}

@end
