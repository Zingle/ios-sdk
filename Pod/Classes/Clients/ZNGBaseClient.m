//
//  ZNGBaseClient.m
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import <AFNetworking/AFHTTPSessionManager.h>
#import "ZNGBaseClient.h"
#import "ZingleSession.h"
#import "ZNGError.h"
#import "ZNGStatus.h"
#import "ZingleSDK.h"

@import SBObjectiveCWrapper;

@interface ZingleSDK ()

- (AFHTTPSessionManager*)sharedSessionManager;

@end

@implementation ZNGBaseClient

NSString * const kBaseClientStatus = @"status";
NSString * const kBaseClientResult = @"result";
NSString * const kJSONParseErrorDomain = @"JSON PARSE ERROR";

- (instancetype) initWithSession:(__weak ZingleSession *)aSession
{
    self = [super init];
    
    if (self != nil) {
        _session = aSession;
        jsonProcessingQueue = aSession.jsonProcessingQueue;
        
        if (jsonProcessingQueue == nil) {
            SBLogError(@"Initialized a %@, but it cannot find a valid JSON processing queue.  We will create a background queue of our own.", [self class]);
            jsonProcessingQueue = dispatch_queue_create("com.zingleme.ZNGBaseClient.backupJsonQueue", 0);
        }
    }
    
    return self;
}

- (void) propogateError:(ZNGError *)error
{
    if (!self.ignoreErrors) {
        self.session.mostRecentError = error;
    }
}

#pragma mark - GET
- (NSURLSessionDataTask *)getListWithParameters:(NSDictionary*)parameters
                                           path:(NSString*)path
                                  responseClass:(Class)responseClass
                                        success:(void (^)(id responseObject, ZNGStatus *status))success
                                        failure:(void (^)(ZNGError* error))failure
{
    SBLogDebug(@"Sending request to %@%@, expecting [%@] in response", self.session.sessionManager.baseURL, path, responseClass);
    SBLogVerbose(@"... with parameters: %@", parameters);
    
    return [self.session.sessionManager GET:path parameters:parameters progress:nil success:^(NSURLSessionDataTask* _Nonnull task, id _Nonnull responseObject) {
        
        NSError* error = nil;
        
        NSDictionary* statusDict = responseObject[kBaseClientStatus];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
        
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
            SBLogDebug(@"Received non-Mantle response to GET of type [%@]", responseClass);
            
            if (success) {
                success(responseObject[kBaseClientResult], status);
            }
            return;
        }
        
        dispatch_async(self->jsonProcessingQueue, ^{
            NSError * error;
            NSArray* result = responseObject[kBaseClientResult];
            NSArray* responseObj = [MTLJSONAdapter modelsOfClass:responseClass fromJSONArray:result error:&error];
            
            if (error) {
                ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
                
                SBLogInfo(@"Received GET response.  Unable to parse a [%@] from the result: %@", responseClass, error.localizedDescription);
                SBLogDebug(@"%@", result);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failure) {
                        failure(zngError);
                    }
                    
                    [self propogateError:zngError];
                });
            } else {
                SBLogDebug(@"Received and parsed GET response of type [%@][%lu]", responseClass, (unsigned long)[responseObj count]);
                
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        success(responseObj, status);
                    });
                }
            }
        });
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        ZNGError * zngError = [[ZNGError alloc] initWithAPIError:error response:task.response];
        SBLogInfo(@"GET failed to %@: %@", path, zngError);
        
        if (failure) {
            failure(zngError);
        }
        
        [self propogateError:zngError];
    }];
}

- (NSURLSessionDataTask *) getWithResourcePath:(NSString *)path
                                 responseClass:(Class)responseClass
                               resultObjectKey:(NSString *)responseKey
                                       success:(void (^)(id _Nonnull, ZNGStatus * _Nonnull))success
                                       failure:(void (^)(ZNGError * _Nonnull))failure
{
    SBLogDebug(@"Sending request to %@%@, expecting %@ in response", self.session.sessionManager.baseURL, path, responseClass);
    
    return [self.session.sessionManager GET:path parameters:nil progress:nil success:^(NSURLSessionDataTask* _Nonnull task, id _Nonnull responseObject) {
        
        NSError* error = nil;
        
        NSDictionary* statusDict = responseObject[kBaseClientStatus];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
        
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
            SBLogDebug(@"Received non-Mantle response to GET of type %@", responseClass);
            
            if (success) {
                success(responseObject[kBaseClientResult], status);
            }
            return;
        }
        
        dispatch_async(self->jsonProcessingQueue, ^{
            NSError * error;
            NSDictionary* result = responseObject[responseKey];
            id responseObj = [MTLJSONAdapter modelOfClass:responseClass fromJSONDictionary:result error:&error];
            
            if (error) {
                ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
                
                SBLogInfo(@"Received GET response.  Unable to parse a %@ from the result: %@", responseClass, error.localizedDescription);
                SBLogDebug(@"%@", result);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failure) {
                        failure(zngError);
                    }
                    
                    [self propogateError:zngError];
                });
                
            } else {
                SBLogDebug(@"Received and parsed GET response of type %@", responseClass);
                
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        success(responseObj, status);
                    });
                }
            }
        });
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        ZNGError * zngError = [[ZNGError alloc] initWithAPIError:error response:task.response];
        SBLogInfo(@"GET failed to %@: %@", path, zngError);
        
        if (failure) {
            failure(zngError);
        }
        
        [self propogateError:zngError];
    }];
}

- (NSURLSessionDataTask*)getWithResourcePath:(NSString*)path
                               responseClass:(Class)responseClass
                                     success:(void (^)(id responseObject, ZNGStatus *status))success
                                     failure:(void (^)(ZNGError* error))failure
{
    return [self getWithResourcePath:path responseClass:responseClass resultObjectKey:kBaseClientResult success:success failure:failure];
}

#pragma mark - PUT
- (NSURLSessionDataTask*)putWithPath:(NSString*)path
                          parameters:(NSDictionary*)parameters
                       responseClass:(Class)responseClass
                             success:(void (^)(id responseObject, ZNGStatus *status))success
                             failure:(void (^)(ZNGError* error))failure
{
    SBLogDebug(@"PUTting to %@%@, expecting %@", self.session.sessionManager.baseURL, path, responseClass);
    SBLogVerbose(@"... with parameters: %@", parameters);
    
    return [self.session.sessionManager PUT:path parameters:parameters success:^(NSURLSessionDataTask* _Nonnull task, id _Nullable responseObject) {
        
        NSError* error = nil;
        
        NSDictionary* statusDict = responseObject[kBaseClientStatus];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
        
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
            SBLogDebug(@"Received non-Mantle response to PUT %@", path);
            
            if (success) {
                success(responseObject[kBaseClientResult], status);
            }
            return;
        }
        
        dispatch_async(self->jsonProcessingQueue, ^{
            NSError * error;
            NSDictionary* result = responseObject[kBaseClientResult];
            id responseObj = [MTLJSONAdapter modelOfClass:responseClass fromJSONDictionary:result error:&error];
            
            if (error) {
                ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
                
                SBLogInfo(@"Unable to parse %@ from %@ PUT request: %@", responseClass, path, error.localizedDescription);
                SBLogDebug(@"%@", result);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failure) {
                        failure(zngError);
                    }
                    
                    [self propogateError:zngError];
                });

            } else {
                SBLogDebug(@"Successfully received %@ from PUT", responseClass);
                
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        success(responseObj, status);
                    });
                }
            }
        });
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        ZNGError * zngError = [[ZNGError alloc] initWithAPIError:error response:task.response];
        SBLogInfo(@"PUT failed to %@: %@", path, zngError);
        
        if (failure) {
            failure(zngError);
        }
        
        [self propogateError:zngError];
    }];
}


#pragma mark - POST
- (NSURLSessionDataTask*)postWithModel:(id<MTLJSONSerializing>)model
                                  path:(NSString*)path
                         responseClass:(Class)responseClass
                               success:(void (^)(id responseObject, ZNGStatus *status))success
                               failure:(void (^)(ZNGError* error))failure
{
    NSDictionary* params;
    
    SBLogDebug(@"POSTing a %@ to %@%@, expecting %@", [(NSObject *)model class], self.session.sessionManager.baseURL, path, responseClass);
    
    if (model) {
        NSError* error = nil;

        params = [MTLJSONAdapter JSONDictionaryFromModel:model error:&error];
        SBLogVerbose(@"... with parameters: %@", params);
 
        if (error) {
            ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
            SBLogWarning(@"Unable to encode %@ to JSON: %@", [(NSObject *)model class], zngError);
            
            if (failure) {
                failure(zngError);
            }
            
            [self propogateError:zngError];
        }
    }
    
    return [self.session.sessionManager POST:path parameters:params progress:nil success:^(NSURLSessionDataTask* _Nonnull task, id _Nonnull responseObject) {
        
        NSError* error = nil;
        
        NSDictionary* statusDict = responseObject[kBaseClientStatus];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
        
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
            SBLogDebug(@"Received non-Mantle response to POST %@", path);
            
            if (success) {
                success(responseObject[kBaseClientResult], status);
            }
            return;
        }
        
        dispatch_async(self->jsonProcessingQueue, ^{
            NSError * error;
            NSDictionary* result = responseObject[kBaseClientResult];
            id responseObj = [MTLJSONAdapter modelOfClass:responseClass fromJSONDictionary:result error:&error];
            
            if (error) {
                ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
                
                SBLogInfo(@"Unable to parse %@ from %@ POST request: %@", responseClass, path, error.localizedDescription);
                SBLogDebug(@"%@", result);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failure) {
                        failure(zngError);
                    }
                    
                    [self propogateError:zngError];
                });
            } else {
                SBLogDebug(@"Successfully received %@ from POST", responseClass);
                
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        success(responseObj, status);
                    });
                }
            }
        });
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        ZNGError * zngError = [[ZNGError alloc] initWithAPIError:error response:task.response];
        SBLogInfo(@"POST failed to %@: %@", path, zngError);
        
        if (failure) {
            failure(zngError);
        }
        
        [self propogateError:zngError];
    }];
}

- (NSURLSessionDataTask*)postWithParameters:(NSDictionary*)parameters
                                       path:(NSString*)path
                              responseClass:(Class)responseClass
                                    success:(void (^)(id responseObject, ZNGStatus *status))success
                                    failure:(void (^)(ZNGError* error))failure
{
    SBLogDebug(@"POSTing to %@%@, expecting %@", self.session.sessionManager.baseURL, path, responseClass);
    SBLogVerbose(@"... with parameters: %@", parameters);
    
    return [self.session.sessionManager POST:path parameters:parameters progress:nil success:^(NSURLSessionDataTask* _Nonnull task, id _Nonnull responseObject) {
        
        NSError* error = nil;
        
        NSDictionary* statusDict = responseObject[kBaseClientStatus];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
        
        if (![responseClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
            SBLogDebug(@"Received non-Mantle response to POST %@", path);
            
            if (success) {
                success(responseObject[kBaseClientResult], status);
            }
            return;
        }
        
        dispatch_async(self->jsonProcessingQueue, ^{
            NSError * error;
            NSDictionary* result = responseObject[kBaseClientResult];
            id responseObj = [MTLJSONAdapter modelOfClass:responseClass fromJSONDictionary:result error:&error];
            
            if (error) {
                ZNGError* zngError = [[ZNGError alloc] initWithDomain:kJSONParseErrorDomain code:0 userInfo:error.userInfo];
                
                SBLogInfo(@"Unable to parse %@ from %@ POST request: %@", responseClass, path, error.localizedDescription);
                SBLogDebug(@"%@", result);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failure) {
                        failure(zngError);
                    }
                    
                    [self propogateError:zngError];
                });
            } else {
                SBLogDebug(@"Successfully received %@ from POST", responseClass);
                
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        success(responseObj, status);
                    });
                }
            }
        });
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        ZNGError * zngError = [[ZNGError alloc] initWithAPIError:error response:task.response];
        SBLogInfo(@"POST failed to %@: %@", path, zngError);
        
        if (failure) {
            failure(zngError);
        }
        
        [self propogateError:zngError];
    }];
}


#pragma mark - DELETE
- (NSURLSessionDataTask*)deleteWithPath:(NSString*)path
                                success:(void (^)(ZNGStatus *status))success
                                failure:(void (^)(ZNGError* error))failure
{
    SBLogDebug(@"Sending DELETE to %@%@", self.session.sessionManager.baseURL, path);
    
    return [self.session.sessionManager DELETE:path parameters:nil success:^(NSURLSessionDataTask* _Nonnull task, id _Nullable responseObject) {
        dispatch_async(self->jsonProcessingQueue, ^{
            NSError* error = nil;
            NSDictionary* statusDict = responseObject[kBaseClientStatus];
            ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:&error];
            
            SBLogDebug(@"DELETE successful");
            
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(status);
                });
            }
        });
    } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
        ZNGError * zngError = [[ZNGError alloc] initWithAPIError:error response:task.response];
        SBLogInfo(@"DELETE failed to %@: %@", path, zngError);
        
        if (failure) {
            failure(zngError);
        }
        
        [self propogateError:zngError];
    }];
}

@end
