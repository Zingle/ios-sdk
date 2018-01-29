//
//  ZNGBaseClient.h
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@class ZNGError;
@class ZNGStatus;

NS_ASSUME_NONNULL_BEGIN

@class ZingleSession;

@interface ZNGBaseClient : NSObject
{
    dispatch_queue_t jsonProcessingQueue;
}

@property (nonatomic, weak, nullable) ZingleSession * session;

/**
 *  Setting this flag will prevent this client from setting the mostRecentError property on its ZingleSession
 */
@property (nonatomic) BOOL ignoreErrors;

#pragma mark - Initialization
- (instancetype) initWithSession:(__weak ZingleSession *)session;

#pragma mark - GET methods

- (NSURLSessionDataTask *)getListWithParameters:(nullable NSDictionary*)parameters
                                         path:(NSString*)path
                                responseClass:(nullable Class)responseClass
                                      success:(nullable void (^)(id responseObject, ZNGStatus *status))success
                                      failure:(nullable void (^)(ZNGError* error))failure;

- (NSURLSessionDataTask*)getWithResourcePath:(NSString*)path
                               responseClass:(nullable Class)responseClass
                                     success:(nullable void (^)(id responseObject, ZNGStatus *status))success
                                     failure:(nullable void (^)(ZNGError* error))failure;

/**
 *  GET request with the ability to specify the result key.  Used when requesting the current contact info from the API root since it is
 *   contained within an "auth" object instead of the usual "result"
 */
- (NSURLSessionDataTask*)getWithResourcePath:(NSString *)path
                               responseClass:(Class)responseClass
                             resultObjectKey:(NSString *)responseKey
                                     success:(void (^)(id _Nonnull, ZNGStatus * _Nonnull))success
                                     failure:(void (^)(ZNGError * _Nonnull))failure;

#pragma mark - POST methods

- (NSURLSessionDataTask*)postWithModel:(nullable id<MTLJSONSerializing>)model
                                  path:(NSString*)path
                         responseClass:(nullable Class)responseClass
                               success:(nullable void (^)(id responseObject, ZNGStatus *status))success
                               failure:(nullable void (^)(ZNGError* error))failure;

- (NSURLSessionDataTask*)postWithParameters:(NSDictionary*)parameters
                                       path:(NSString*)path
                              responseClass:(nullable Class)responseClass
                                    success:(nullable void (^)(id responseObject, ZNGStatus *status))success
                                    failure:(nullable void (^)(ZNGError* error))failure;

#pragma mark - PUT methods

- (NSURLSessionDataTask*)putWithPath:(NSString*)path
                          parameters:(NSDictionary*)parameters
                       responseClass:(nullable Class)responseClass
                             success:(nullable void (^)(id responseObject, ZNGStatus *status))success
                             failure:(nullable void (^)(ZNGError* error))failure;

#pragma mark - DELETE methods

- (NSURLSessionDataTask*)deleteWithPath:(NSString*)path
                                success:(nullable void (^)(ZNGStatus *status))success
                                failure:(nullable void (^)(ZNGError* error))failure;

@end

NS_ASSUME_NONNULL_END
