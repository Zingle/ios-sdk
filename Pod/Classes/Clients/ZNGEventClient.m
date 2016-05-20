//
//  ZNGEventClient.m
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import "ZNGEventClient.h"

@implementation ZNGEventClient

#pragma mark - GET methods

+ (void)eventListWithParameters:(NSDictionary*)parameters
                    withServiceId:(NSString*)serviceId
                          success:(void (^)(NSArray* events, ZNGStatus* status))success
                          failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/events", serviceId];
    
    [self getListWithParameters:parameters
                           path:path
                  responseClass:[ZNGEvent class]
                        success:success
                        failure:failure];
}

+ (void)eventWithId:(NSString*)eventId
        withServiceId:(NSString*)serviceId
              success:(void (^)(ZNGEvent* event, ZNGStatus* status))success
              failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/events/%@", serviceId, eventId];
    
    [self getWithResourcePath:path
                responseClass:[ZNGEvent class]
                      success:success
                      failure:failure];
}

#pragma mark - POST methods

/*
 // FIXME: Currently returns a 500 error.
+ (void)sendEvent:(ZNGNewEvent*)newEvent
      withServiceId:(NSString*)serviceId
            success:(void (^)(ZNGEvent* event, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure
{
    if (newEvent.eventType == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: newEvent.eventType"];
    }
    
    if (newEvent.contactId == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: newEvent.contactId"];
    }
    
    if (newEvent.body == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: newEvent.body"];
    }
    
    NSString* path = [NSString stringWithFormat:@"services/%@/events", serviceId];
    
    [self postWithModel:newEvent
                   path:path
          responseClass:[ZNGEvent class]
                success:success
                failure:failure];
}
*/

@end
