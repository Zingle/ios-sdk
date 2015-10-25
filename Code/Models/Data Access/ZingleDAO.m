//
//  ZingleDAO.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleDAO.h"
#import "NSMutableDictionary+json.h"
#import "ZingleSDK.h"
#import "ZingleDAOResponse.h"

NSString * const ZINGLE_REQUEST_METHOD_GET    = @"GET";
NSString * const ZINGLE_REQUEST_METHOD_POST   = @"POST";
NSString * const ZINGLE_REQUEST_METHOD_PUT    = @"PUT";
NSString * const ZINGLE_REQUEST_METHOD_DELETE = @"DELETE";


// Private
@interface ZingleDAO()

@property (nonatomic) BOOL loading;
@property (nonatomic) int _logLevel;

@end

// Public
@implementation ZingleDAO

#pragma mark -
#pragma mark Initialization

- (id)init
{
    if( self = [super init] )
    {
        [self resetDefaults];
    }
    
    return self;
}

- (void)resetDefaults
{
    self.loading = NO;
    self.requestMethod = ZINGLE_REQUEST_METHOD_GET;
    [self clearQueryVars];
    [self clearPostVars];
}

#pragma mark -
#pragma mark Setters

- (void)setRequestMethod:(NSString *)requestMethod
{
    NSArray *validRequestMethods = [NSArray arrayWithObjects:ZINGLE_REQUEST_METHOD_GET, ZINGLE_REQUEST_METHOD_POST, ZINGLE_REQUEST_METHOD_PUT, ZINGLE_REQUEST_METHOD_DELETE, nil];
    
    if( ![validRequestMethods containsObject:requestMethod] )
    {
        [NSException raise:@"ZINGLE_SDK_INVALID_REQUEST_METHOD" format:@"Invalid request method."];
    }
    else
    {
        _requestMethod = requestMethod;
    }
}

- (void)setQueryVar:(NSString *)value forKey:(NSString *)key
{
    [self.queryVars setObject:value forKey:key];
}

- (void)deleteQueryVarForKey:(NSString *)key
{
    [self.queryVars removeObjectForKey:key];
}

- (void)clearQueryVars
{
    self.queryVars = [NSMutableDictionary dictionary];
}

- (void)setPostVar:(id)value forKey:(NSString *)key
{
    [self.postVars setObject:value forKey:key];
}

- (void)clearPostVars
{
    self.postVars = [NSMutableDictionary dictionary];
}

#pragma mark -
#pragma mark Getters

- (NSString *)queryString
{
    return [self.queryVars queryString];
}

- (NSString *)jsonPayload
{
    return [self.postVars jsonString];
}

- (NSString *)requestURLForURI:(NSString *)requestURI
{
    NSString *requestURL = [NSString stringWithFormat:@"https://%@/%@", ZINGLE_API_HOST, ZINGLE_API_VERSION, nil];
    
    if( requestURI != nil && [requestURI length] > 0 )
    {
        requestURL = [requestURL stringByAppendingFormat:@"/%@", requestURI, nil];
    }
    
    if( [self.queryVars count] > 0 )
    {
        requestURL = [requestURL stringByAppendingFormat:@"?%@", [self queryString]];
    }
    
    return requestURL;
}

- (BOOL)isLoading
{
    return self.loading;
}

# pragma mark -
# pragma mark Commands

- (void)validateRequest
{
    if( ![[ZingleSDK sharedSDK] hasCredentials] )
    {
        [NSException raise:@"ZINGLE_SDK_MISSING_CREDENTIALS" format:@"The Zingle SDK does not have credentials supplied.  Please call [ZingleSDK setToken:andKey:]"];
    }
    else if( self.requestMethod == nil || [self.requestMethod length] < 3 )
    {
        [NSException raise:@"ZINGLE_SDK_INVALID_REQUEST_METHOD" format:@"Invalid Request Method."];
    }
}

- (NSURLRequest *)buildRequestWithURI:(NSString *)requestURI
{
    [self validateRequest];
    
    NSURL *url = [NSURL URLWithString:[self requestURLForURI:requestURI]];
    NSString *payload = [self jsonPayload];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:self.requestMethod];
    
    if( [self.requestMethod isEqualToString:@"POST"] || [self.requestMethod isEqualToString:@"PUT"] )
    {
        [request setHTTPBody:[payload dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    NSString *basicAuthString = [[ZingleSDK sharedSDK] basicAuthString];
    NSString *basicAuth = [NSString stringWithFormat:@"Basic %@", basicAuthString];
    [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    return request;
}

- (void)sendAsynchronousRequestTo:(NSString *)requestURI
                  completionBlock:(void (^) (ZingleDAOResponse *response))completionBlock
                       errorBlock:(void (^) (ZingleDAOResponse *response, NSError *error))errorBlock
{
    NSURLRequest *request = [self buildRequestWithURI:requestURI];
    
    self.loading = YES;
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
         
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if( self.loading ) {
                    
                    NSString *requestURL = [self requestURLForURI:requestURI];
                    
                    [self log:[NSString stringWithFormat:@"START Async Request: %@ %@", self.requestMethod, requestURL] forLevel:ZINGLE_LOG_LEVEL_NOTICE];
                    
                    ZingleDAOResponse *zingleResponse = [[ZingleDAOResponse alloc] init];
                    zingleResponse.requestedMethod    = self.requestMethod;
                    zingleResponse.requestedURL       = requestURL;
                    zingleResponse.requestedPayload   = [self jsonPayload];
                    zingleResponse.urlResponse        = response;
                    zingleResponse.urlResponseData    = data;
                    zingleResponse.urlResponseError   = error;
                    
                    self.loading = NO;
                    NSError *zingleError = [zingleResponse error];
                    if( zingleError == nil ) {
                        [self log:[NSString stringWithFormat:@"END Async Request: %@", requestURL] forLevel:ZINGLE_LOG_LEVEL_NOTICE];
                        [self log:[NSString stringWithFormat:@"%@", zingleResponse] forLevel:ZINGLE_LOG_LEVEL_VERBOSE];
                        
                        completionBlock( zingleResponse );
                    } else {
                        [self log:[NSString stringWithFormat:@"END Async Request: %@", requestURL] forLevel:ZINGLE_LOG_LEVEL_NOTICE];
                        [self log:[NSString stringWithFormat:@"%@", zingleResponse] forLevel:ZINGLE_LOG_LEVEL_VERBOSE];
                        
                        [self log:[NSString stringWithFormat:@"Async Error: %@", zingleError]  forLevel:ZINGLE_LOG_LEVEL_ERROR];
                        
                        errorBlock( zingleResponse, zingleError );
                    }
                }
                
            });
            
    }];
}

- (ZingleDAOResponse *)sendSynchronousRequestTo:(NSString *)requestURI error:(NSError **)zingleError
{
    NSURLRequest *request = [self buildRequestWithURI:requestURI];
    NSURLResponse* response;
    NSError* error = nil;
    
    self.loading = YES;
    NSString *requestURL = [self requestURLForURI:requestURI];
    
    [self log:[NSString stringWithFormat:@"Start Sync Request: %@ %@", self.requestMethod, requestURL] forLevel:ZINGLE_LOG_LEVEL_NOTICE];
    
    NSData* resultData = [NSURLConnection sendSynchronousRequest:request
                                               returningResponse:&response
                                                           error:&error];
    
    if( self.loading )
    {
        self.loading = NO;
        ZingleDAOResponse *zingleResponse = [[ZingleDAOResponse alloc] init];
        zingleResponse.requestedMethod    = self.requestMethod;
        zingleResponse.requestedURL       = [self requestURLForURI:requestURI];
        zingleResponse.requestedPayload   = [self jsonPayload];
        zingleResponse.urlResponse        = response;
        zingleResponse.urlResponseError   = error;
        zingleResponse.urlResponseData    = resultData;
        
        [self log:[NSString stringWithFormat:@"Sync Request Completed for: %@", requestURL] forLevel:ZINGLE_LOG_LEVEL_NOTICE];
        [self log:[NSString stringWithFormat:@"%@", zingleResponse] forLevel:ZINGLE_LOG_LEVEL_VERBOSE];
        
        NSError *zingleResponseError = [zingleResponse error];
        if( zingleError != NULL && zingleResponseError ) {
            
            [self log:[NSString stringWithFormat:@"Sync Request Completed with Error: %@", zingleResponseError]  forLevel:ZINGLE_LOG_LEVEL_ERROR];
            
            *zingleError = zingleResponseError;
        }
        
        return zingleResponse;
    }
    
    return nil;
}

- (void)cancel
{
    // This will cancel the callback even if the request is successful
    self.loading = NO;
}

- (void)log:(NSString *)message forLevel:(int)logLevel
{
    if( logLevel <= [[ZingleSDK sharedSDK] globalLogLevel] ||
        logLevel <= [self logLevel] ) {
    }
}

- (void)setLogLevel:(int)logLevel
{
    self._logLevel = logLevel;
}

- (int)logLevel
{
    return self._logLevel;
}

@end
