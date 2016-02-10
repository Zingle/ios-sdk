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
#import "ZNGError.h"

@interface ZNGBaseClient : NSObject

#pragma mark Generic methods to GET and POST

+ (NSURLSessionDataTask *)getListWithParameters:(NSDictionary *)parameters
                                           path:(NSString *)path
                                 responseClass:(Class)responseClass
                                        success:(void(^)(id responseObject))success
                                        failure:(void(^)(ZNGError *error))failure;

+ (NSURLSessionDataTask *)getWithResourcePath:(NSString *)path
                               responseClass:(Class)responseClass
                                      success:(void(^)(id responseObject))success
                                      failure:(void(^)(ZNGError *error))failure;

+ (NSURLSessionDataTask *)postWithModel:(id<MTLJSONSerializing>)model
                                   path:(NSString *)path
                         responseClass:(Class)responseClass
                                success:(void (^)(id responseObject))success
                                failure:(void (^)(ZNGError *error))failure;

+ (NSURLSessionDataTask *)putWithPath:(NSString *)path
                           parameters:(NSDictionary *)parameters
                       responseClass:(Class)responseClass
                              success:(void (^)(id responseObject))success
                              failure:(void (^)(ZNGError *error))failure;

+ (NSURLSessionDataTask *)deleteWithPath:(NSString *)path
                                 success:(void (^)())success
                                 failure:(void (^)(ZNGError *error))failure;

@end
