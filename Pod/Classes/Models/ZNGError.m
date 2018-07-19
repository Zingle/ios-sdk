//
//  ZNGError.m
//  Pods
//
//  Created by Ryan Farley on 2/5/16.
//
//

#import "ZNGError.h"
#import <AFNetworking/AFHTTPSessionManager.h>

@implementation ZNGError

NSString *const kErrorStatus = @"status";
NSString *const kErrorCode = @"error_code";
NSString *const kErrorText = @"text";
NSString *const kErrorStatusCode = @"status_code";
NSString *const kErrorDescription = @"description";
NSString* const kZingleErrorDomain = @"ZINGLE ERROR";

static NSString * const EmailUnverifiedDescription = @"email is not verified";

- (id)initWithAPIError:(NSError *)error
{
    NSDictionary *status;
    NSInteger code;
    
    NSData* errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    if (errorData) {
        NSDictionary* serializedData = [NSJSONSerialization JSONObjectWithData:errorData options:kNilOptions error:nil];
        status = [serializedData objectForKey:kErrorStatus];
        code = [[status objectForKey:kErrorCode] integerValue];
    } else {
        code = error.code;
        status = error.userInfo;
    }

    self = [super initWithDomain:kZingleErrorDomain code:code userInfo:status];
    
    if (self) {
        _errorText = [status objectForKey:kErrorText];
        _httpStatusCode = [[status objectForKey:kErrorStatusCode] integerValue];
        _zingleErrorCode = [[status objectForKey:kErrorCode] integerValue];
        _errorDescription = [status objectForKey:kErrorDescription];
    }
    
    return self;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"Zingle Error (%lu): %@ %@", (unsigned long)self.code, self.errorText, self.errorDescription];
}

- (BOOL) isAuthenticationFailure
{
    switch (self.httpStatusCode) {
        case 401:
        case 403:
            return YES;
        default:
            return NO;
    }
}

- (BOOL) isUnverifiedEmailError
{
    if (self.httpStatusCode != 401) {
        return NO;
    }
    
    NSRange unverifiedStringRange = [self.errorDescription rangeOfString:EmailUnverifiedDescription options:NSCaseInsensitiveSearch];
    return (unverifiedStringRange.location != NSNotFound);
}

@end
