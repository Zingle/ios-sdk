//
//  ZNGEventClient.h
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGEvent.h"
#import "ZNGNewEvent.h"

@interface ZNGEventClient : ZNGBaseClient

#pragma mark - GET methods

+ (void)eventListWithParameters:(NSDictionary*)parameters
                  withServiceId:(NSString*)serviceId
                        success:(void (^)(NSArray* events, ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure;

+ (void)eventWithId:(NSString*)eventId
      withServiceId:(NSString*)serviceId
            success:(void (^)(ZNGEvent* event, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure;

#pragma mark - POST methods

/*
 // FIXME: Currently returns a 500 error.
+ (void)sendEvent:(ZNGNewEvent*)newEvent
      withServiceId:(NSString*)serviceId
            success:(void (^)(ZNGEvent* event, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure;
 */

@end
