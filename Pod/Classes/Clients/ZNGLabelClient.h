//
//  ZNGLabelClient.h
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGLabel.h"

@interface ZNGLabelClient : ZNGBaseClient

#pragma mark - GET methods

+ (void)labelListWithParameters:(NSDictionary*)parameters
                  withServiceId:(NSString *)serviceId
                        success:(void (^)(NSArray* contactFields, ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure;

+ (void)labelWithId:(NSString*)labelId
      withServiceId:(NSString *)serviceId
            success:(void (^)(ZNGLabel* label, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure;

#pragma mark - POST methods

+ (void)saveLabel:(ZNGLabel*)label
    withServiceId:(NSString *)serviceId
          success:(void (^)(ZNGLabel* label, ZNGStatus* status))success
          failure:(void (^)(ZNGError* error))failure;

#pragma mark - PUT methods

+ (void)updateLabelWithId:(NSString*)labelId
            withServiceId:(NSString *)serviceId
           withParameters:(NSDictionary*)parameters
                  success:(void (^)(ZNGLabel* label, ZNGStatus* status))success
                  failure:(void (^)(ZNGError* error))failure;

#pragma mark - DELETE methods

+ (void)deleteLabelWithId:(NSString*)labelId
            withServiceId:(NSString *)serviceId
                  success:(void (^)(ZNGStatus* status))success
                  failure:(void (^)(ZNGError* error))failure;

@end
