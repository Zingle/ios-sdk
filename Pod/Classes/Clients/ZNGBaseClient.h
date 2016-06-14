//
//  ZNGBaseClient.h
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import "ZingleSDK.h"
#import "ZNGStatus.h"
#import "ZNGError.h"

@interface ZNGBaseClient : NSObject

#pragma mark - GET methods

- (NSURLSessionDataTask *)getListWithParameters:(NSDictionary*)parameters
                                         path:(NSString*)path
                                responseClass:(Class)responseClass
                                      success:(void (^)(id responseObject, ZNGStatus *status))success
                                      failure:(void (^)(ZNGError* error))failure;

+ (NSURLSessionDataTask*)getListWithParameters:(NSDictionary*)parameters
                                          path:(NSString*)path
                                 responseClass:(Class)responseClass
                                       success:(void (^)(id responseObject, ZNGStatus *status))success
                                       failure:(void (^)(ZNGError* error))failure;

- (NSURLSessionDataTask*)getWithResourcePath:(NSString*)path
                               responseClass:(Class)responseClass
                                     success:(void (^)(id responseObject, ZNGStatus *status))success
                                     failure:(void (^)(ZNGError* error))failure;

+ (NSURLSessionDataTask*)getWithResourcePath:(NSString*)path
                               responseClass:(Class)responseClass
                                     success:(void (^)(id responseObject, ZNGStatus *status))success
                                     failure:(void (^)(ZNGError* error))failure;

#pragma mark - POST methods

+ (NSURLSessionDataTask*)postWithModel:(id<MTLJSONSerializing>)model
                                  path:(NSString*)path
                         responseClass:(Class)responseClass
                               success:(void (^)(id responseObject, ZNGStatus *status))success
                               failure:(void (^)(ZNGError* error))failure;

+ (NSURLSessionDataTask*)postWithParameters:(NSDictionary*)parameters
                                       path:(NSString*)path
                              responseClass:(Class)responseClass
                                    success:(void (^)(id responseObject, ZNGStatus *status))success
                                    failure:(void (^)(ZNGError* error))failure;

#pragma mark - PUT methods

- (NSURLSessionDataTask*)putWithPath:(NSString*)path
                          parameters:(NSDictionary*)parameters
                       responseClass:(Class)responseClass
                             success:(void (^)(id responseObject, ZNGStatus *status))success
                             failure:(void (^)(ZNGError* error))failure;

+ (NSURLSessionDataTask*)putWithPath:(NSString*)path
                          parameters:(NSDictionary*)parameters
                       responseClass:(Class)responseClass
                             success:(void (^)(id responseObject, ZNGStatus *status))success
                             failure:(void (^)(ZNGError* error))failure;

#pragma mark - DELETE methods

+ (NSURLSessionDataTask*)deleteWithPath:(NSString*)path
                                success:(void (^)(ZNGStatus *status))success
                                failure:(void (^)(ZNGError* error))failure;

@end
