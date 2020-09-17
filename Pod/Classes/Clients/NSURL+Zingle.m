//
//  NSURL+Zingle.m
//  Pods
//
//  Created by Jason Neel on 12/15/16.
//
//

#import "NSURL+Zingle.h"

@implementation NSURL (Zingle)

- (BOOL) isZingleProduction
{
    // A non-nil, empty string indicates production
    return [[self _zingleServerPrefix] isEqualToString:@""];
}

- (NSString *)_zingleServerPrefix
{
    NSURLComponents * components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    NSString * host = components.host;
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"^((\\w+)-)?\\w+\\.zingle.me$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray<NSTextCheckingResult *> * matches = [regex matchesInString:host options:0 range:NSMakeRange(0, [host length])];
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
    
    if (prefixRange.location == NSNotFound) {
        // We did not find capture group 2.  This indicates a production Zingle URL with no prefix.
        return @"";
    }
    
    return [host substringWithRange:prefixRange];
}

/**
 *  Returns the instance name from a Zingle URL with multiple subdomains, e.g. `qa05` from `https://qa05.qa.denver.zingle.me/`.
 *  Returns nil for a non-Zingle URL or a Zingle URL of the old, hyphenated form, e.g. `https://qa-app.zingle.me/`
 */
- (NSString *)_multipleSubdomainInstanceName
{
    NSURLComponents * components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    NSString * host = components.host;
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\w+).(\\w+\\.)+zingle.me$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray<NSTextCheckingResult *> * matches = [regex matchesInString:host options:0 range:NSMakeRange(0, [host length])];
    NSTextCheckingResult * match = [matches firstObject];
    
    if (match.numberOfRanges < 2) {
        return nil;
    }
    
    NSRange instanceNameRange = [match rangeAtIndex:1];
    
    if (instanceNameRange.location == NSNotFound) {
        // Something has gone wacky
        return nil;
    }
    
    return [host substringWithRange:instanceNameRange];
}

- (NSURL * _Nullable)apiUrlV1
{
    NSString * prefix = [self _zingleServerPrefix];
    
    if (prefix == nil) {
        return nil;
    }
    
    NSString * path = ([prefix length] > 0) ? [NSString stringWithFormat:@"https://%@-api.zingle.me/v1", prefix] : @"https://api.zingle.me/v1";
    return [NSURL URLWithString:path];
}

- (NSURL * _Nullable)apiUrlV2
{
    NSString * prefix = [self _zingleServerPrefix];
    
    if (prefix == nil) {
        return nil;
    }
    
    NSString * path = ([prefix length] > 0) ? [NSString stringWithFormat:@"https://%@-api.zingle.me/v2", prefix] : @"https://api.zingle.me/v2";
    return [NSURL URLWithString:path];
}

- (NSURL * _Nullable)authUrl
{
    NSString * prefix = [self _zingleServerPrefix];
    
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
    NSString * prefix = [self _zingleServerPrefix];
    
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

- (NSURL *)webAppUrl
{
    NSString * prefix = [self _zingleServerPrefix];
    
    if (prefix == nil) {
        return nil;
    }
    
    NSString * path = ([prefix length] > 0) ? [NSString stringWithFormat:@"https://%@-app.zingle.me/", prefix] : @"https://app.zingle.me/";
    return [NSURL URLWithString:path];
}

+ (NSURL * _Nonnull)nativeLoginUrl
{
    return [NSURL URLWithString:@"zingle://login"];
}

@end
