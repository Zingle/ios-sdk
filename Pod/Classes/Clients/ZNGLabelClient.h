//
//  ZNGLabelClient.h
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGBaseClientService.h"
#import "ZNGLabel.h"

@interface ZNGLabelClient : ZNGBaseClientService

#pragma mark - GET methods

- (void)labelListWithParameters:(NSDictionary*)parameters
                        success:(void (^)(NSArray* contactFields, ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure;

- (void)labelWithId:(NSString*)labelId
            success:(void (^)(ZNGLabel* label, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure;

#pragma mark - POST methods

- (void)saveLabel:(ZNGLabel*)label
          success:(void (^)(ZNGLabel* label, ZNGStatus* status))success
          failure:(void (^)(ZNGError* error))failure;

#pragma mark - PUT methods

- (void)updateLabelWithId:(NSString*)labelId
           withParameters:(NSDictionary*)parameters
                  success:(void (^)(ZNGLabel* label, ZNGStatus* status))success
                  failure:(void (^)(ZNGError* error))failure;

#pragma mark - DELETE methods

- (void)deleteLabelWithId:(NSString*)labelId
                  success:(void (^)(ZNGStatus* status))success
                  failure:(void (^)(ZNGError* error))failure;

@end
