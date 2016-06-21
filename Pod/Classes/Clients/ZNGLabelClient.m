//
//  ZNGLabelClient.m
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGLabelClient.h"

@implementation ZNGLabelClient

#pragma mark - GET methods

- (void)labelListWithParameters:(NSDictionary*)parameters
                        success:(void (^)(NSArray* contactFields, ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/contact-labels", self.serviceId];
    
    [self getListWithParameters:parameters
                           path:path
                  responseClass:[ZNGLabel class]
                        success:success
                        failure:failure];
}

- (void)labelWithId:(NSString*)labelId
            success:(void (^)(ZNGLabel* label, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/contact-labels/%@", self.serviceId, labelId];
    
    [self getWithResourcePath:path
                responseClass:[ZNGLabel class]
                      success:success
                      failure:failure];
}

#pragma mark - POST methods

- (void)saveLabel:(ZNGLabel*)label
          success:(void (^)(ZNGLabel* label, ZNGStatus* status))success
          failure:(void (^)(ZNGError* error))failure
{
    if (label.displayName == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: label.displayName"];
    }
    if (label.backgroundColor == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: label.backgroundColor"];
    }
    if (label.textColor == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: label.textColor"];
    }
    
    NSString *path = [NSString stringWithFormat:@"services/%@/contact-labels", self.serviceId];
    
    [self postWithModel:label
                   path:path
          responseClass:[ZNGLabel class]
                success:success
                failure:failure];
}

#pragma mark - PUT methods

- (void)updateLabelWithId:(NSString*)labelId
           withParameters:(NSDictionary*)parameters
                  success:(void (^)(ZNGLabel* label, ZNGStatus* status))success
                  failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/contact-labels/%@", self.serviceId, labelId];
    
    [self putWithPath:path
           parameters:parameters
        responseClass:[ZNGLabel class]
              success:success
              failure:failure];
}

#pragma mark - DELETE methods

- (void)deleteLabelWithId:(NSString*)labelId
                  success:(void (^)(ZNGStatus* status))success
                  failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/contact-labels/%@", self.serviceId, labelId];
    
    [self deleteWithPath:path
                 success:success
                 failure:failure];
}

@end
