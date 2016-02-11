//
//  ZNGContactFieldClient.m
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGContactFieldClient.h"

@implementation ZNGContactFieldClient

#pragma mark - GET methods

+ (void)contactFieldListWithParameters:(NSDictionary*)parameters
                         withServiceId:(NSString *)serviceId
                               success:(void (^)(NSArray* contactFields))success
                               failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/contact-custom-fields", serviceId];
    
    [self getListWithParameters:parameters
                           path:path
                  responseClass:[ZNGContactField class]
                        success:success
                        failure:failure];
}

+ (void)contactFieldWithId:(NSString*)contactFieldId
             withServiceId:(NSString *)serviceId
                   success:(void (^)(ZNGContactField* contactField))success
                   failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/contact-custom-fields/%@", serviceId, contactFieldId];
    
    [self getWithResourcePath:path
                responseClass:[ZNGContactField class]
                      success:success
                      failure:failure];
}

#pragma mark - POST methods

+ (void)saveContactField:(ZNGContactField*)contactField
           withServiceId:(NSString *)serviceId
                 success:(void (^)(ZNGContactField* contactField))success
                 failure:(void (^)(ZNGError* error))failure
{
    if (contactField.displayName == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: contactField.displayName"];
    }
    
    NSString *path = [NSString stringWithFormat:@"services/%@/contact-custom-fields", serviceId];
    
    [self postWithModel:contactField
                   path:path
          responseClass:[ZNGContactField class]
                success:success
                failure:failure];
}

#pragma mark - PUT methods

+ (void)updateContactFieldWithId:(NSString*)contactFieldId
                   withServiceId:(NSString *)serviceId
                  withParameters:(NSDictionary*)parameters
                         success:(void (^)(ZNGContactField* contactField))success
                         failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/contact-custom-fields/%@", serviceId, contactFieldId];
    
    [self putWithPath:path
           parameters:parameters
        responseClass:[ZNGContactField class]
              success:success
              failure:failure];
}

#pragma mark - DELETE methods

+ (void)deleteContactFieldWithId:(NSString*)contactFieldId
                   withServiceId:(NSString *)serviceId
                         success:(void (^)())success
                         failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/contact-custom-fields/%@", serviceId, contactFieldId];
    
    [self deleteWithPath:path
                 success:success
                 failure:failure];
}

@end
