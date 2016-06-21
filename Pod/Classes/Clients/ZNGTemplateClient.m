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

- (void)templateListWithParameters:(NSDictionary*)parameters
                           success:(void (^)(NSArray* templ, ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/templates", self.serviceId];
    
    [self getListWithParameters:parameters
                           path:path
                  responseClass:[ZNGTemplate class]
                        success:success
                        failure:failure];
}

@end