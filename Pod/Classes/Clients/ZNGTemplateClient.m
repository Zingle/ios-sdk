//
//  ZNGTemplateClient.m
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGTemplateClient.h"

@implementation ZNGTemplateClient

#pragma mark - GET methods

+ (void)templateListWithParameters:(NSDictionary*)parameters
                     withServiceId:(NSString *)serviceId
                           success:(void (^)(NSArray* templ))success
                           failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/templates", serviceId];
    
    [self getListWithParameters:parameters
                           path:path
                  responseClass:[ZNGTemplate class]
                        success:success
                        failure:failure];
}

+ (void)templateWithId:(NSString*)templateId
         withServiceId:(NSString *)serviceId
               success:(void (^)(ZNGTemplate* templ))success
               failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/templates/%@", serviceId, templateId];
    
    [self getWithResourcePath:path
                responseClass:[ZNGTemplate class]
                      success:success
                      failure:failure];
}

#pragma mark - POST methods

+ (void)saveTemplate:(ZNGTemplate*)templ
       withServiceId:(NSString *)serviceId
             success:(void (^)(ZNGTemplate* templ))success
             failure:(void (^)(ZNGError* error))failure
{
    if (templ.displayName == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: templ.displayName"];
    }
    if (templ.type == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: templ.type"];
    }
    if (templ.body == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: templ.body"];
    }
    
    NSString *path = [NSString stringWithFormat:@"services/%@/templates", serviceId];
    
    [self postWithModel:templ
                   path:path
          responseClass:[ZNGTemplate class]
                success:success
                failure:failure];
}

#pragma mark - PUT methods

+ (void)updateTemplateWithId:(NSString*)templateId
               withServiceId:(NSString *)serviceId
              withParameters:(NSDictionary*)parameters
                     success:(void (^)(ZNGTemplate* templ))success
                     failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/templates/%@", serviceId, templateId];
    
    [self putWithPath:path
           parameters:parameters
        responseClass:[ZNGTemplate class]
              success:success
              failure:failure];
}

#pragma mark - DELETE methods

+ (void)deleteTemplateWithId:(NSString*)templateId
               withServiceId:(NSString *)serviceId
                     success:(void (^)())success
                     failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/templates/%@", serviceId, templateId];
    
    [self deleteWithPath:path
                 success:success
                 failure:failure];
}

@end
