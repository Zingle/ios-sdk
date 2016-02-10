//
//  ZNGBaseClient.m
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGConstants.h"

@implementation ZNGBaseClient

+ (AFHTTPSessionManager*)sessionManager {
  return [[ZingleSDK sharedSDK] sharedSessionManager];
}

#pragma mark Generic methods to GET and POST

+ (NSURLSessionDataTask*)
    getListWithParameters:(NSDictionary*)parameters
                     path:(NSString*)path
            responseClass:(Class)responseClass
                  success:(void (^)(id responseObject))success
                  failure:(void (^)(ZNGError* error))failure {
  return [[self sessionManager] GET:path
      parameters:parameters
      success:^(NSURLSessionDataTask* _Nonnull task,
                id _Nonnull responseObject) {
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
          success(responseObject[@"result"]);
          return;
        }
        
        NSError* error = nil;
        NSArray* result = responseObject[@"result"];
        NSArray* responseObj = [MTLJSONAdapter modelsOfClass:responseClass
                                               fromJSONArray:result
                                                       error:&error];
                                                       
        if (error) {
          ZNGError* zngError =
              [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain
                                          code:0
                                      userInfo:error.userInfo];
                                      
          if (failure) {
            failure(zngError);
          }
        } else {
          if (success) {
            success(responseObj);
          }
        }
      }
      failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        if (failure) {
          failure([self zingleError:error]);
        }
      }];
}

+ (NSURLSessionDataTask*)
    getWithResourcePath:(NSString*)path
          responseClass:(Class)responseClass
                success:(void (^)(id responseObject))success
                failure:(void (^)(ZNGError* error))failure {
  return [[self sessionManager] GET:path
      parameters:nil
      success:^(NSURLSessionDataTask* _Nonnull task,
                id _Nonnull responseObject) {
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
          success(responseObject[@"result"]);
          return;
        }
        
        NSError* error = nil;
        NSDictionary* result = responseObject[@"result"];
        
        id responseObj = [MTLJSONAdapter modelOfClass:responseClass
                                   fromJSONDictionary:result
                                                error:&error];
                                                
        if (error) {
          ZNGError* zngError =
              [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain
                                          code:0
                                      userInfo:error.userInfo];
                                      
          if (failure) {
            failure(zngError);
          }
        } else {
          if (success) {
            success(responseObj);
          }
        }
      }
      failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        if (failure) {
          failure([self zingleError:error]);
        }
      }];
}

+ (NSURLSessionDataTask*)postWithModel:(id<MTLJSONSerializing>)model
                                  path:(NSString*)path
                         responseClass:(Class)responseClass
                               success:(void (^)(id responseObject))success
                               failure:(void (^)(ZNGError* error))failure {
  NSDictionary* params;
  
  if (model) {
    NSError* error = nil;
    params = [MTLJSONAdapter JSONDictionaryFromModel:model error:&error];
    
    if (error) {
      ZNGError* zngError =
          [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain
                                      code:0
                                  userInfo:error.userInfo];
                                  
      if (failure) {
        failure(zngError);
      }
    }
  }
  
  return [[self sessionManager] POST:path
      parameters:params
      success:^(NSURLSessionDataTask* _Nonnull task,
                id _Nonnull responseObject) {
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
          success(responseObject[@"result"]);
          return;
        }
        
        NSError* error = nil;
        NSDictionary* result = responseObject[@"result"];
        
        id responseObj = [MTLJSONAdapter modelOfClass:responseClass
                                   fromJSONDictionary:result
                                                error:&error];
                                                
        if (error) {
          ZNGError* zngError =
              [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain
                                          code:0
                                      userInfo:error.userInfo];
                                      
          if (failure) {
            failure(zngError);
          }
        } else {
          if (success) {
            success(responseObj);
          }
        }
      }
      failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        if (failure) {
          failure([self zingleError:error]);
        }
      }];
}

+ (NSURLSessionDataTask*)putWithPath:(NSString*)path
                          parameters:(NSDictionary*)parameters
                       responseClass:(Class)responseClass
                             success:(void (^)(id responseObject))success
                             failure:(void (^)(ZNGError* error))failure {
  return [[self sessionManager] PUT:path
      parameters:parameters
      success:^(NSURLSessionDataTask* _Nonnull task,
                id _Nullable responseObject) {
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
          success(responseObject[@"result"]);
          return;
        }
        
        NSError* error = nil;
        NSDictionary* result = responseObject[@"result"];
        
        id responseObj = [MTLJSONAdapter modelOfClass:responseClass
                                   fromJSONDictionary:result
                                                error:&error];
                                                
        if (error) {
          ZNGError* zngError =
              [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain
                                          code:0
                                      userInfo:error.userInfo];
                                      
          if (failure) {
            failure(zngError);
          }
        } else {
          if (success) {
            success(responseObj);
          }
        }
      }
      failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        if (failure) {
          failure([self zingleError:error]);
        }
      }];
}

+ (NSURLSessionDataTask*)deleteWithPath:(NSString*)path
                                success:(void (^)())success
                                failure:(void (^)(ZNGError* error))failure {
  return [[self sessionManager] DELETE:path
      parameters:nil
      success:^(NSURLSessionDataTask* _Nonnull task,
                id _Nullable responseObject) {
        if (success) {
          success();
        }
      }
      failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        if (failure) {
          failure([self zingleError:error]);
        }
      }];
}

+ (ZNGError*)zingleError:(NSError*)error {
  NSData* errorData =
      error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
  NSDictionary* serializedData =
      [NSJSONSerialization JSONObjectWithData:errorData
                                      options:kNilOptions
                                        error:nil];
  NSDictionary* status = [serializedData objectForKey:@"status"];
  ZNGError* zngError = [[ZNGError alloc]
      initWithDomain:kZingleErrorDomain
                code:[[status objectForKey:@"error_code"] integerValue]
            userInfo:status];
            
  zngError.errorText = [status objectForKey:@"text"];
  zngError.httpStatusCode = [[status objectForKey:@"status_code"] integerValue];
  zngError.zingleErrorCode = [[status objectForKey:@"error_code"] integerValue];
  zngError.errorDescription = [status objectForKey:@"description"];
  return zngError;
}

@end
