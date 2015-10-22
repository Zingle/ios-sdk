//
//  ZingleDAOResponse.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleDAOResponse.h"
#import "ZingleSDK.h"
#import "NSMutableDictionary+json.h"
#import "ZingleError.h"

int const ZINGLE_HTTP_STATUS_UNKNOWN            = 0;
int const ZINGLE_HTTP_STATUS_OK                 = 200;
int const ZINGLE_HTTP_STATUS_BAD_REQUEST        = 400;
int const ZINGLE_HTTP_STATUS_UNAUTHORIZED       = 401;
int const ZINGLE_HTTP_STATUS_FORBIDDEN          = 403;
int const ZINGLE_HTTP_STATUS_NOT_FOUND          = 404;
int const ZINGLE_HTTP_STATUS_METHOD_NOT_ALLOWED = 405;
int const ZINGLE_HTTP_STATUS_SERVER_ERROR       = 500;

@interface ZingleDAOResponse()

@property (nonatomic, retain) NSURLResponse *urlResponse;
@property (nonatomic, retain) NSError *urlResponseError;
@property (nonatomic, retain) NSData *urlResponseData;

@end

@implementation ZingleDAOResponse

- (BOOL)successful
{
    return ([self httpStatusCode] == ZINGLE_HTTP_STATUS_OK);
}

- (int)httpStatusCode
{
    if( [self requestCompleted] ) {
        if( self.urlResponseError ) {
            if( self.urlResponseError.code == kCFURLErrorUserCancelledAuthentication ) {
                return ZINGLE_HTTP_STATUS_UNAUTHORIZED;
            }
        } else {
            id zingleStatusCode = [self statusField:@"status_code"];
            if( zingleStatusCode ) {
                return [zingleStatusCode intValue];
            }
        }
    }
    
    if( self.urlResponse ) {
        return (int)[(NSHTTPURLResponse *)self.urlResponse statusCode];
    }
    
    return ZINGLE_HTTP_STATUS_UNKNOWN;
}

- (NSDictionary *)allHeaders
{
    if( [self requestCompleted] ) {
        return [(NSHTTPURLResponse *)self.urlResponse allHeaderFields];
    }
    
    return [NSDictionary dictionary];
}

- (id)headerValueForKey:(NSString *)key
{
    return [[self allHeaders] objectForKey:key];
}

- (NSString *)responseAsString
{
    if( [self requestCompleted] ) {
        return [[NSString alloc] initWithData:self.urlResponseData encoding:NSUTF8StringEncoding];
    }
    
    return @"{}";
}

- (NSMutableDictionary *)responseAsDictionary
{
    if( [self requestCompleted] ) {
        return [NSMutableDictionary dictionaryWithJsonData:self.urlResponseData];
    }
    
    return [NSMutableDictionary dictionary];
}

- (id)result
{
    if( [self successful] ) {
        NSMutableDictionary *lastResponse = [self responseAsDictionary];
        return [lastResponse objectAtPath:@"result" expectedClass:nil];
    }
    
    return nil;
}

- (NSMutableDictionary *)status
{
    NSMutableDictionary *lastResponse = [self responseAsDictionary];
    return [lastResponse objectAtPath:@"status" expectedClass:nil default:[NSMutableDictionary dictionary]];
}

- (id)statusField:(NSString *)field
{
    return [[self status] objectForKey:field];
}

- (NSError *)requestError
{
    NSError *error = self.urlResponseError;
    
    if( error && self.urlResponseError.code == kCFURLErrorUserCancelledAuthentication ) {
        error = nil;
    }
    return error;
}

 - (ZingleError *)zingleError
{
    if( [self requestCompleted] && ![self successful] ) {
        
        id httpErrorCode = [self statusField:@"status_code"];
        id zingleErrorCode  = [self statusField:@"error_code"];
        
        int httpCode = (httpErrorCode) ? [httpErrorCode intValue] : [self httpStatusCode];
        int zingleCode = (zingleErrorCode) ? [zingleErrorCode intValue] : [self httpStatusCode];
        ZingleError *error = [[ZingleError alloc] initWithDomain:ZINGLE_ERROR_DOMAIN code:zingleCode userInfo:[NSDictionary dictionaryWithObject:[self statusField:@"description"] forKey:NSLocalizedDescriptionKey]];
        error.zingleErrorCode     = zingleCode;
        error.httpStatusCode      = httpCode;
        error.errorText           = [self statusField:@"text"];
        error.errorDescription    = [self statusField:@"description"];
        
        return error;
    }
    
    return nil;
}

- (NSError *)error
{
    ZingleError *zingleError = [self zingleError];
    if( zingleError ) {
        return zingleError;
    }
    
    NSError *requestError = [self requestError];
    if( requestError ) {
        return requestError;
    }
    
    return nil;
}

- (BOOL)requestCompleted
{
    return (self.urlResponseData != nil);
}

- (void)setUrlResponseData:(NSData *)urlResponseData
{
    _urlResponseData = urlResponseData;
}

- (void)setUrlResponseError:(NSError *)urlResponseError
{
    _urlResponseError = urlResponseError;
}

- (void)setUrlResponse:(NSURLResponse *)urlResponse
{
    _urlResponse = urlResponse;
}

- (NSString *)description
{
    NSString *description = @"<ZinglDAOResponse> {\r";
    description = [description stringByAppendingFormat:@"    method: %@\r", self.requestedMethod];
    description = [description stringByAppendingFormat:@"    url: %@\r", self.requestedURL];
    description = [description stringByAppendingFormat:@"    postData: %@\r", self.requestedPayload];
    if( [self error] ) {
        description = [description stringByAppendingFormat:@"    errorCode: %i\r", (int)[self error].code];
    }
    description = [description stringByAppendingFormat:@"    httpStatusCode: %i\r", [self httpStatusCode]];
    description = [description stringByAppendingFormat:@"    response: %@\r", [self responseAsString]];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}

@end
