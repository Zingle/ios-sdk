//
//  ZNGContactServiceClient.h
//  Pods
//
//  Created by Robert Harrison on 5/23/16.
//
//

#import "ZNGBaseClient.h"

@interface ZNGContactServiceClient : ZNGBaseClient

#pragma mark - GET methods

- (void)contactServiceListWithParameters:(NSDictionary*)parameters
                                 success:(void (^)(NSArray* contactServices, ZNGStatus* status))success
                                 failure:(void (^)(ZNGError* error))failure;

@end
