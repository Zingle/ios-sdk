//
//  ZNGError.m
//  Pods
//
//  Created by Ryan Farley on 2/5/16.
//
//

#import "ZNGError.h"
#import <AFNetworking/AFNetworking.h>
#import "ZNGConstants.h"

@implementation ZNGError

- (id)initWithAPIError:(NSError *)error
{
    NSData* errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    NSDictionary* serializedData = [NSJSONSerialization JSONObjectWithData:errorData options:kNilOptions error:nil];
    NSDictionary* status = [serializedData objectForKey:@"status"];
    
    self = [super initWithDomain:kZingleErrorDomain code:[[status objectForKey:@"error_code"] integerValue] userInfo:status];
    
    if (self) {
        _errorText = [status objectForKey:@"text"];
        _httpStatusCode = [[status objectForKey:@"status_code"] integerValue];
        _zingleErrorCode = [[status objectForKey:@"error_code"] integerValue];
        _errorDescription = [status objectForKey:@"description"];
    }
    
    return self;
}

@end
