//
//  ZNGEventClient.m
//  Pods
//
//  Created by Jason Neel on 7/11/16.
//
//

#import "ZNGEventClient.h"
#import "ZNGEvent.h"

@implementation ZNGEventClient

- (void)eventListWithParameters:(NSDictionary*)parameters
                        success:(void (^)(NSArray<ZNGEvent *> * events, ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure
{
    NSString * path = [NSString stringWithFormat:@"services/%@/events", self.serviceId];
    
    [self getListWithParameters:parameters path:path responseClass:[ZNGEvent class] success:success failure:failure];
}

- (void)eventWithId:(NSString*)eventId
            success:(void (^)(ZNGEvent * event, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure
{
    NSString * path = [NSString stringWithFormat:@"services/%@/events/%@", self.serviceId, eventId];
    
    [self getWithResourcePath:path responseClass:[ZNGEvent class] success:success failure:failure];
}

@end
