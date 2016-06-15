//
//  ZNGTemplateClient.h
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGBaseClientService.h"
#import "ZNGTemplate.h"

@interface ZNGTemplateClient : ZNGBaseClientService

#pragma mark - GET methods

- (void)templateListWithParameters:(NSDictionary*)parameters
                           success:(void (^)(NSArray* templ, ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure;

@end
