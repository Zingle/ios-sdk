//
//  ZNGBaseClient.m
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import <AFNetworking/AFNetworking.h>
#import "ZNGBaseClient.h"

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
    return [[self sessionManager] GET:path parameters:parameters success:^(NSURLSessionDataTask* _Nonnull task, id _Nonnull responseObject) {
        
        NSError* error = nil;

        NSDictionary* statusDict = responseObject[kBaseClientStatus];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
        
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
            if (success) {
                success(responseObject[kBaseClientResult], status);
            }
            return;
        }
        
        NSArray* result = responseObject[kBaseClientResult];
        NSArray* responseObj = [MTLJSONAdapter modelsOfClass:responseClass fromJSONArray:result error:&error];
        
        if (error) {
            ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
            
            if (failure) {
                failure(zngError);
            }
        } else {
            if (success) {
                success(responseObj, status);
            }
        }
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        if (failure) {
            ZNGError* zngError = [[ZNGError alloc] initWithAPIError:error];
            failure(zngError);
        }
    }];
}

+ (NSURLSessionDataTask*)getWithResourcePath:(NSString*)path
                               responseClass:(Class)responseClass
                                     success:(void (^)(id responseObject, ZNGStatus *status))success
                                     failure:(void (^)(ZNGError* error))failure
{
    return [[self sessionManager] GET:path parameters:nil success:^(NSURLSessionDataTask* _Nonnull task, id _Nonnull responseObject) {
        
        NSError* error = nil;
        
        NSDictionary* statusDict = responseObject[kBaseClientStatus];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
        
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
            if (success) {
                success(responseObject[kBaseClientResult], status);
            }
            return;
        }
        
        NSDictionary* result = responseObject[kBaseClientResult];
        id responseObj = [MTLJSONAdapter modelOfClass:responseClass fromJSONDictionary:result error:&error];
        
        if (error) {
            ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
            
            if (failure) {
                failure(zngError);
            }
        } else {
            if (success) {
                success(responseObj, status);
            }
        }
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        if (failure) {
            ZNGError* zngError = [[ZNGError alloc] initWithAPIError:error];
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
    
    if (model) {
        NSError* error = nil;
        params = [MTLJSONAdapter JSONDictionaryFromModel:model error:&error];
        
        if (error) {
            ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
            
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
            if (success) {
                success(responseObject[kBaseClientResult], status);
            }
            return;
        }
        
        NSDictionary* result = responseObject[kBaseClientResult];
        id responseObj = [MTLJSONAdapter modelOfClass:responseClass fromJSONDictionary:result error:&error];
        
        if (error) {
            ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
            
            if (failure) {
                failure(zngError);
            }
        } else {
            if (success) {
                success(responseObj, status);
            }
        }
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        if (failure) {
            ZNGError* zngError = [[ZNGError alloc] initWithAPIError:error];
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
    return [[self sessionManager] PUT:path parameters:parameters success:^(NSURLSessionDataTask* _Nonnull task, id _Nullable responseObject) {
        
        NSError* error = nil;
        
        NSDictionary* statusDict = responseObject[kBaseClientStatus];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
        
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
            if (success) {
                success(responseObject[kBaseClientResult], status);
            }
            return;
        }
        
        NSDictionary* result = responseObject[kBaseClientResult];
        id responseObj = [MTLJSONAdapter modelOfClass:responseClass fromJSONDictionary:result error:&error];
        
        if (error) {
            ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
            
            if (failure) {
                failure(zngError);
            }
        } else {
            if (success) {
                success(responseObj, status);
            }
        }
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        if (failure) {
            ZNGError* zngError = [[ZNGError alloc] initWithAPIError:error];
            failure(zngError);
        }
    }];
}

#pragma mark - DELETE methods

+ (NSURLSessionDataTask*)deleteWithPath:(NSString*)path
                                success:(void (^)(ZNGStatus *status))success
                                failure:(void (^)(ZNGError* error))failure
{
    return [[self sessionManager] DELETE:path parameters:nil success:^(NSURLSessionDataTask* _Nonnull task, id _Nullable responseObject) {
        
        NSError* error = nil;
        
        NSDictionary* statusDict = responseObject[kBaseClientStatus];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
        
        if (success) {
            success(status);
        }
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        if (failure) {
            ZNGError* zngError = [[ZNGError alloc] initWithAPIError:error];
            failure(zngError);
        }
    }];
}

@end
