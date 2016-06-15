//
//  ZNGServiceClient.h
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import "ZNGBaseClientAccount.h"
#import "ZNGService.h"

@interface ZNGServiceClient : ZNGBaseClientAccount

#pragma mark - GET methods

- (void)serviceListWithSuccess:(void (^)(NSArray* services, ZNGStatus* status))success
                       failure:(void (^)(ZNGError* error))failure;

- (void)serviceListWithParameters:(NSDictionary*)parameters
                          success:(void (^)(NSArray* services, ZNGStatus* status))success
                          failure:(void (^)(ZNGError* error))failure;

- (void)serviceWithId:(NSString*)serviceId
              success:(void (^)(ZNGService* service, ZNGStatus* status))success
              failure:(void (^)(ZNGError* error))failure;

@end
