//
//  ZNGBaseClient.m
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import <AFNetworking/AFNetworking.h>
#import "ZNGBaseClient.h"
#import "ZNGLogging.h"

static const int zngLogLevel = ZNGLogLevelDebug;

@interface ZingleSDK ()

- (AFHTTPSessionManager*)sharedSessionManager;

@end

@implementation ZNGBaseClient

NSString *const kBaseClientStatus = @"status";
NSString *const kBaseClientResult = @"result";
NSString* const kJSONParseErrorDomain = @"JSON PARSE ERROR";

+ (AFHTTPSessionManager*)sessionManager
{
    return [[ZingleSDK sharedSDK] sharedSessionManager];
}

#pragma mark - GET methods

+ (NSURLSessionDataTask*)getListWithParameters:(NSDictionary*)parameters
                                          path:(NSString*)path
                                 responseClass:(Class)responseClass
                                       success:(void (^)(id responseObject, ZNGStatus *status))success
                                       failure:(void (^)(ZNGError* error))failure
{
    ZNGLogDebug(@"Sending request to %@, expecting [%@] in response", path, responseClass);
    
    return [[self sessionManager] GET:path parameters:parameters success:^(NSURLSessionDataTask* _Nonnull task, id _Nonnull responseObject) {
        
        NSError* error = nil;

        NSDictionary* statusDict = responseObject[kBaseClientStatus];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
        
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
            ZNGLogDebug(@"Received non-Mantle response to GET of type [%@]", responseClass);
            
            if (success) {
                success(responseObject[kBaseClientResult], status);
            }
            return;
        }
        
        NSArray* result = responseObject[kBaseClientResult];
        NSArray* responseObj = [MTLJSONAdapter modelsOfClass:responseClass fromJSONArray:result error:&error];
        
        if (error) {
            ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
            
            ZNGLogInfo(@"Received GET response.  Unable to parse a [%@] from the result: %@", responseClass, error.localizedDescription);
            ZNGLogDebug(@"%@", result);
            
            if (failure) {
                failure(zngError);
            }
        } else {
            ZNGLogDebug(@"Received and parsed GET response of type [%@][%llu]", responseClass, [responseObj count]);
            
            if (success) {
                success(responseObj, status);
            }
        }
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        ZNGError* zngError = [[ZNGError alloc] initWithAPIError:error];
        ZNGLogInfo(@"GET failed to %@: %@", path, zngError);
        
        if (failure) {
            failure(zngError);
        }
    }];
}

+ (NSURLSessionDataTask*)getWithResourcePath:(NSString*)path
                               responseClass:(Class)responseClass
                                     success:(void (^)(id responseObject, ZNGStatus *status))success
                                     failure:(void (^)(ZNGError* error))failure
{
    ZNGLogDebug(@"Sending request to %@, expecting %@ in response", path, responseClass);
    
    return [[self sessionManager] GET:path parameters:nil success:^(NSURLSessionDataTask* _Nonnull task, id _Nonnull responseObject) {
        
        NSError* error = nil;
        
        NSDictionary* statusDict = responseObject[kBaseClientStatus];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
        
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
            ZNGLogDebug(@"Received non-Mantle response to GET of type %@", responseClass);
            
            if (success) {
                success(responseObject[kBaseClientResult], status);
            }
            return;
        }
        
        NSDictionary* result = responseObject[kBaseClientResult];
        id responseObj = [MTLJSONAdapter modelOfClass:responseClass fromJSONDictionary:result error:&error];
        
        if (error) {
            ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
            
            ZNGLogInfo(@"Received GET response.  Unable to parse a %@ from the result: %@", responseClass, error.localizedDescription);
            ZNGLogDebug(@"%@", result);
            
            if (failure) {
                failure(zngError);
            }
        } else {
            ZNGLogDebug(@"Received and parsed GET response of type %@", responseClass);
            
            if (success) {
                success(responseObj, status);
            }
        }
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        ZNGError* zngError = [[ZNGError alloc] initWithAPIError:error];
        ZNGLogInfo(@"GET failed to %@: %@", path, zngError);
        
        if (failure) {
            failure(zngError);
        }
    }];
}

#pragma mark - POST methods

+ (NSURLSessionDataTask*)postWithModel:(id<MTLJSONSerializing>)model
                                  path:(NSString*)path
                         responseClass:(Class)responseClass
                               success:(void (^)(id responseObject, ZNGStatus *status))success
                               failure:(void (^)(ZNGError* error))failure
{
    NSDictionary* params;
    
    ZNGLogDebug(@"POSTing a %@ to %@, expecting %@", [model class], path, responseClass);
    
    if (model) {
        NSError* error = nil;
        params = [MTLJSONAdapter JSONDictionaryFromModel:model error:&error];
        
        if (error) {
            ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
            ZNGLogWarn(@"Unable to encode %@ to JSON: %@", [model class], zngError);
            
            if (failure) {
                failure(zngError);
            }
        }
    }
    
    return [[self sessionManager] POST:path parameters:params success:^(NSURLSessionDataTask* _Nonnull task, id _Nonnull responseObject) {
        
        NSError* error = nil;
        
        NSDictionary* statusDict = responseObject[kBaseClientStatus];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
        
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
            ZNGLogDebug(@"Received non-Mantle response to POST %@", path);
            
            if (success) {
                success(responseObject[kBaseClientResult], status);
            }
            return;
        }
        
        NSDictionary* result = responseObject[kBaseClientResult];
        id responseObj = [MTLJSONAdapter modelOfClass:responseClass fromJSONDictionary:result error:&error];
        
        if (error) {
            ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
            
            ZNGLogInfo(@"Unable to parse %@ from %@ POST request: %@", responseClass, path, error.localizedDescription);
            ZNGLogDebug(@"%@", result);
            
            if (failure) {
                failure(zngError);
            }
        } else {
            ZNGLogDebug(@"Successfully received %@ from POST", responseClass);
            
            if (success) {
                success(responseObj, status);
            }
        }
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        ZNGError* zngError = [[ZNGError alloc] initWithAPIError:error];
        ZNGLogInfo(@"POST failed to %@: %@", path, zngError);
        
        if (failure) {
            failure(zngError);
        }
    }];
}

+ (NSURLSessionDataTask*)postWithParameters:(NSDictionary*)parameters
                                       path:(NSString*)path
                              responseClass:(Class)responseClass
                                    success:(void (^)(id responseObject, ZNGStatus *status))success
                                    failure:(void (^)(ZNGError* error))failure
{
    ZNGLogDebug(@"POSTing to %@, expecting %@", path, responseClass);
    
    return [[self sessionManager] POST:path parameters:parameters success:^(NSURLSessionDataTask* _Nonnull task, id _Nonnull responseObject) {
        
        NSError* error = nil;
        
        NSDictionary* statusDict = responseObject[kBaseClientStatus];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
        
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
            ZNGLogDebug(@"Received non-Mantle response to POST %@", path);
            
            if (success) {
                success(responseObject[kBaseClientResult], status);
            }
            return;
        }
        
        NSDictionary* result = responseObject[kBaseClientResult];
        id responseObj = [MTLJSONAdapter modelOfClass:responseClass fromJSONDictionary:result error:&error];
        
        if (error) {
            ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
            
            ZNGLogInfo(@"Unable to parse %@ from %@ POST request: %@", responseClass, path, error.localizedDescription);
            ZNGLogDebug(@"%@", result);
            
            if (failure) {
                failure(zngError);
            }
        } else {
            ZNGLogDebug(@"Successfully received %@ from POST", responseClass);
            
            if (success) {
                success(responseObj, status);
            }
        }
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        ZNGError* zngError = [[ZNGError alloc] initWithAPIError:error];
        ZNGLogInfo(@"POST failed to %@: %@", path, zngError);
        
        if (failure) {
            failure(zngError);
        }
    }];
    
}

#pragma mark - PUT methods

+ (NSURLSessionDataTask*)putWithPath:(NSString*)path
                          parameters:(NSDictionary*)parameters
                       responseClass:(Class)responseClass
                             success:(void (^)(id responseObject, ZNGStatus *status))success
                             failure:(void (^)(ZNGError* error))failure
{
    ZNGLogDebug(@"PUTting to %@, expecting %@", path, responseClass);
    
    return [[self sessionManager] PUT:path parameters:parameters success:^(NSURLSessionDataTask* _Nonnull task, id _Nullable responseObject) {
        
        NSError* error = nil;
        
        NSDictionary* statusDict = responseObject[kBaseClientStatus];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
        
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
            ZNGLogDebug(@"Received non-Mantle response to PUT %@", path);
            
            if (success) {
                success(responseObject[kBaseClientResult], status);
            }
            return;
        }
        
        NSDictionary* result = responseObject[kBaseClientResult];
        id responseObj = [MTLJSONAdapter modelOfClass:responseClass fromJSONDictionary:result error:&error];
        
        if (error) {
            ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
            
            ZNGLogInfo(@"Unable to parse %@ from %@ PUT request: %@", responseClass, path, error.localizedDescription);
            ZNGLogDebug(@"%@", result);
            
            if (failure) {
                failure(zngError);
            }
        } else {
            ZNGLogDebug(@"Successfully received %@ from PUT", responseClass);
            
            if (success) {
                success(responseObj, status);
            }
        }
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        ZNGError* zngError = [[ZNGError alloc] initWithAPIError:error];
        ZNGLogInfo(@"PUT failed to %@: %@", path, zngError);
        
        if (failure) {
            failure(zngError);
        }
    }];
}

#pragma mark - DELETE methods

+ (NSURLSessionDataTask*)deleteWithPath:(NSString*)path
                                success:(void (^)(ZNGStatus *status))success
                                failure:(void (^)(ZNGError* error))failure
{
    ZNGLogDebug(@"Sending DELETE to %@", path);
    
    return [[self sessionManager] DELETE:path parameters:nil success:^(NSURLSessionDataTask* _Nonnull task, id _Nullable responseObject) {
        
        NSError* error = nil;
        
        NSDictionary* statusDict = responseObject[kBaseClientStatus];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
        
        ZNGLogDebug(@"DELETE successful");
        
        if (success) {
            success(status);
        }
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        ZNGError* zngError = [[ZNGError alloc] initWithAPIError:error];
        ZNGLogInfo(@"DELETE failed to %@: %@", path, zngError);
        
        if (failure) {
            failure(zngError);
        }
    }];
}

@end
