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

NS_ASSUME_NONNULL_BEGIN

@class ZingleSession;

@interface ZNGBaseClient : NSObject

@property (nonatomic, weak, nullable) ZingleSession * session;

#pragma mark - Initialization
- (instancetype) initWithSession:(__weak ZingleSession *)session;

#pragma mark - GET methods

- (NSURLSessionDataTask *)getListWithParameters:(nullable NSDictionary*)parameters
                                         path:(NSString*)path
                                responseClass:(Class)responseClass
                                      success:(nullable void (^)(id responseObject, ZNGStatus *status))success
                                      failure:(nullable void (^)(ZNGError* error))failure;

- (NSURLSessionDataTask*)getWithResourcePath:(NSString*)path
                               responseClass:(Class)responseClass
                                     success:(nullable void (^)(id responseObject, ZNGStatus *status))success
                                     failure:(nullable void (^)(ZNGError* error))failure;

#pragma mark - POST methods

- (NSURLSessionDataTask*)postWithModel:(nullable id<MTLJSONSerializing>)model
                                  path:(NSString*)path
                         responseClass:(Class)responseClass
                               success:(nullable void (^)(id responseObject, ZNGStatus *status))success
                               failure:(nullable void (^)(ZNGError* error))failure;

- (NSURLSessionDataTask*)postWithParameters:(NSDictionary*)parameters
                                       path:(NSString*)path
                              responseClass:(Class)responseClass
                                    success:(nullable void (^)(id responseObject, ZNGStatus *status))success
                                    failure:(nullable void (^)(ZNGError* error))failure;

#pragma mark - PUT methods

- (NSURLSessionDataTask*)putWithPath:(NSString*)path
                          parameters:(NSDictionary*)parameters
                       responseClass:(Class)responseClass
                             success:(nullable void (^)(id responseObject, ZNGStatus *status))success
                             failure:(nullable void (^)(ZNGError* error))failure;

#pragma mark - DELETE methods

- (NSURLSessionDataTask*)deleteWithPath:(NSString*)path
                                success:(nullable void (^)(ZNGStatus *status))success
                                failure:(nullable void (^)(ZNGError* error))failure;

@end

NS_ASSUME_NONNULL_END
