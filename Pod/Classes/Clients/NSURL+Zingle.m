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
        // This does not appear to be a hyphenated or production Zingle URL
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
    NSString * instanceSubdomain = [self _multipleSubdomainInstanceName];
    
    if (prefix != nil) {
        if ([prefix length] > 0) {
            return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@-%@.zingle.me/", prefix, service]];
        }
        
        // Production!
        return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.zingle.me/", service]];
    }
    
    if ([instanceSubdomain length] > 0) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.%@.zingle.me/", service, instanceSubdomain]];
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
