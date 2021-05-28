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
    NSString * host = self.host;
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"^\\w+(?:-\\d)?\\.zingle\\.(?:me|medallia\\.com)$"
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:nil];
    NSArray<NSTextCheckingResult *> * matches = [regex matchesInString:host options:0 range:NSMakeRange(0, [host length])];
    return (matches.count == 1);
}

/**
 * Newer kind of Zingle URLs uses service name with suffix by a hyphen. (https://app-3.zingle.den.medallia.com)
 */
- (NSString *)_zingleServerSuffix
{
    NSString * host = self.host;
    NSString * regexPattern = @"^\\w+(?:-(\\d))\\.zingle(?:\\.den)?\\.medallia\\.com$";
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:regexPattern
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:nil];
    NSArray<NSTextCheckingResult *> * matches = [regex matchesInString:host options:0 range:NSMakeRange(0, [host length])];
    if (matches.count != 1) {
        // This does not appear to be a newer kind of Zingle URL
        return nil;
    }
    
    // We found a suffix. Return it.
    NSTextCheckingResult * match = matches[0];
    NSRange prefixRange = [match rangeAtIndex:1];

    return [host substringWithRange:prefixRange];
}


/**
 * For now, we have prefixes only for QA and CI environments  (https://qa-api.zingle.me and https://ci-api.zingle.me)
 */
- (NSString *)_zingleServerPrefix
{
    NSURLComponents * components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    NSString * host = components.host;
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\w+)-\\w+\\.zingle.me$"
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:nil];
    NSArray<NSTextCheckingResult *> * matches = [regex matchesInString:host options:0 range:NSMakeRange(0, [host length])];
    if (matches.count != 1) {
        // This does not appear to be a hyphenated Zingle URL
        return nil;
    }
    
    // We found a prefix. Return it.
    NSTextCheckingResult * match = matches[0];
    NSRange prefixRange = [match rangeAtIndex:1];
    
    return [host substringWithRange:prefixRange];
}

/**
 *  Returns the instance name from a Zingle URL with multiple subdomains, e.g. `qa05.qa.denver` from `https://api.qa05.qa.denver.zingle.me/`.
 *  Returns nil for a non-Zingle URL or a Zingle URL of the old, hyphenated form, e.g. `https://qa-api.zingle.me/`
 */
- (NSString *)_multipleSubdomainInstanceName
{
    NSURLComponents * components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    NSString * host = components.host;
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"^\\w+\\.((\\w+\\.)*\\w+)\\.zingle.me$" options:NSRegularExpressionCaseInsensitive error:nil];
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

- (NSURL *) _urlForService:(NSString *)service
{
    NSString * prefix = [self _zingleServerPrefix];
    if ([prefix length] > 0) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@-%@.zingle.me/", prefix, service]];
    }
    
    NSString * instanceSubdomain = [self _multipleSubdomainInstanceName];
    if ([instanceSubdomain length] > 0) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.%@.zingle.me/", service, instanceSubdomain]];
    }

    NSString * suffix = [self _zingleServerSuffix];
    if ([suffix length] > 0) {
        if ([self isZingleProduction]) {
            return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@-%@.zingle.medallia.com/", service, suffix]];
        } else {
            return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@-%@.zingle.den.medallia.com/", service, suffix]];
        }
    }

    if ([self isZingleProduction]) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.zingle.me/", service]];
    }
    
    // Non-Zingle
    return nil;
}

- (NSURL * _Nullable)apiUrlV1
{
    NSURL * url = [self _urlForService:@"api"];
    
    if (url == nil) {
        return nil;
    }
    
    NSURLComponents * components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.path = [url.path stringByAppendingPathComponent:@"v1"];
    
    return components.URL;
}

- (NSURL * _Nullable)apiUrlV2
{
    NSURL * url = [self _urlForService:@"api"];
    
    if (url == nil) {
        return nil;
    }
    
    NSURLComponents * components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.path = [url.path stringByAppendingPathComponent:@"v2"];
    
    return components.URL;
}

- (NSURL * _Nullable)authUrl
{
    NSURL * url = [self _urlForService:@"app"];
    
    if (url == nil) {
        return nil;
    }
    
    NSURLComponents * components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.path = [url.path stringByAppendingPathComponent:@"auth"];
    
    return components.URL;
}

- (NSURL *)socketUrl
{
    NSString * suffix = [self _zingleServerSuffix];
    if (suffix.length > 0) {
        // Newer kind server URL (app-3.zingle.den.medallia.com)
        return [self _urlForService:@"socket"];
    }
    
    if ([self isZingleProduction]) {
        return [NSURL URLWithString:@"https://socket.zingle.me/"];
    }
    
    NSString * subdomain = [self _multipleSubdomainInstanceName];
    
    // Special socket case for local dev/ngrok
    if ((subdomain != nil) && ([@[@"ngrok", @"dev"] containsObject:subdomain])) {
        return [NSURL URLWithString:@"https://socket.ngrok.zingle.me:7999/"];
    }
    
    // Otherwise, generally socket lives on the web app URL at port 8000
    NSURL * url = [self _urlForService:@"app"];
    
    if (url == nil) {
        return nil;
    }
    
    NSURLComponents * components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.port = @(8000);
    return components.URL;
}

- (NSURL *)webAppUrl
{
    return [self _urlForService:@"app"];
}

+ (NSURL * _Nonnull)nativeLoginUrl
{
    return [NSURL URLWithString:@"zingle://login"];
}

@end
