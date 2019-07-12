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
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"^(https?:\\/\\/)?((\\w+)-)?\\w+.zingle.me(\\/.*)?$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray<NSTextCheckingResult *> * matches = [regex matchesInString:path options:0 range:NSMakeRange(0, [path length])];
    NSTextCheckingResult * match = [matches firstObject];
    
    if (match == nil) {
        // This does not appear to be a Zingle URL
        return nil;
    }
    
    if (match.numberOfRanges < 4) {
        // We did not find capture group 3.  This indicates a production Zingle URL with no prefix.
        return @"";
    }
    
    // We found a prefix.  Return it.
    NSRange prefixRange = [match rangeAtIndex:3];
    
    if (prefixRange.location == NSNotFound) {
        // We did not find capture group 3.  This indicates a production Zingle URL with no prefix.
        return @"";
    }
    
    return [path substringWithRange:prefixRange];
}

- (NSURL * _Nullable)apiUrlV1
{
    NSString * prefix = [self zingleServerPrefix];
    
    if (prefix == nil) {
        return nil;
    }
    
    NSString * path = ([prefix length] > 0) ? [NSString stringWithFormat:@"https://%@-api.zingle.me/v1", prefix] : @"https://api.zingle.me/v1";
    return [NSURL URLWithString:path];
}

- (NSURL * _Nullable)authUrl
{
    NSString * prefix = [self zingleServerPrefix];
    
    if (prefix == nil) {
        return nil;
    }
    
    if ([prefix length] == 0) {
        // Empty string means production (per `zingleServerPrefix` documentation)
        return [NSURL URLWithString:@"https://app.zingle.me/auth"];
    }
    
    // We have a non-production prefix
    NSString * path = [NSString stringWithFormat:@"https://%@-app.zingle.me/auth", prefix];
    return [NSURL URLWithString:path];
}

- (NSURL *)socketUrl
{
    NSString * prefix = [self zingleServerPrefix];
    
    if (prefix == nil) {
        return nil;
    }
    
    if ([prefix length] == 0) {
        return [NSURL URLWithString:@"https://socket.zingle.me/"];
    }
    
    // We have a non-production prefix
    NSString * path = [NSString stringWithFormat:@"https://%@-app.zingle.me:8000/", prefix];
    return [NSURL URLWithString:path];
}

@end
