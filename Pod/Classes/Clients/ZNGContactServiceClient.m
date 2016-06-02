//
//  ZNGContactServiceClient.m
//  Pods
//
//  Created by Robert Harrison on 5/23/16.
//
//

#import "ZNGContactServiceClient.h"
#import "ZNGContactService.h"

@implementation ZNGContactServiceClient

#pragma mark - GET methods

+ (void)contactServiceListWithParameters:(NSDictionary*)parameters
                                 success:(void (^)(NSArray* contactServices, ZNGStatus* status))success
                                 failure:(void (^)(ZNGError* error))failure
{
    NSString* path = @"contact_services";
    
    [self getListWithParameters:parameters
                           path:path
                  responseClass:[ZNGContactService class]
                        success:success
                        failure:failure];
}

@end
