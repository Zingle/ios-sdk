//
//  NSURL+Zingle.m
//  Pods
//
//  Created by Jason Neel on 12/15/16.
//
//

#import "NSURL+Zingle.h"

@implementation NSURL (Zingle)

- (NSString *)zingleServerPrefix
{
    NSString * path = self.absoluteString;
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"^((\\w+)-)?\\w+.zingle.me$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray<NSTextCheckingResult *> * matches = [regex matchesInString:path options:0 range:NSMakeRange(0, [path length])];
    NSTextCheckingResult * match = [matches firstObject];
    
    if (match == nil) {
        // This does not appear to be a Zingle URL
        return nil;
    }
    
    if (match.numberOfRanges < 3) {
        // We did not find capture group 2.  This indicates a production Zingle URL with no prefix.
        return @"";
    }
    
    // We found a prefix.  Return it.
    NSRange prefixRange = [match rangeAtIndex:2];
    return [path substringWithRange:prefixRange];
}


@end
