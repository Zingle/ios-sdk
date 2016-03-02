//
//  ZNGError.m
//  Pods
//
//  Created by Ryan Farley on 2/5/16.
//
//

#import "ZNGError.h"
#import <AFNetworking/AFNetworking.h>

@implementation ZNGError

NSString *const kErrorStatus = @"status";
NSString *const kErrorCode = @"error_code";
NSString *const kErrorText = @"text";
NSString *const kErrorStatusCode = @"status_code";
NSString *const kErrorDescription = @"description";
NSString* const kZingleErrorDomain = @"ZINGLE ERROR";

- (id)initWithAPIError:(NSError *)error
{
    NSData* errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    NSDictionary* serializedData = [NSJSONSerialization JSONObjectWithData:errorData options:kNilOptions error:nil];
    NSDictionary* status = [serializedData objectForKey:kErrorStatus];
    
    self = [super initWithDomain:kZingleErrorDomain code:[[status objectForKey:kErrorCode] integerValue] userInfo:status];
    
    if (self) {
        _errorText = [status objectForKey:kErrorText];
        _httpStatusCode = [[status objectForKey:kErrorStatusCode] integerValue];
        _zingleErrorCode = [[status objectForKey:kErrorCode] integerValue];
        _errorDescription = [status objectForKey:kErrorDescription];
    }
    
    return self;
}

@end
