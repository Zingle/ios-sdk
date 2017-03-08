//
//  ZNGStubbedEventClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 3/7/17.
//  Copyright © 2017 Zingle. All rights reserved.
//

#import "ZNGStubbedEventClient.h"

@implementation ZNGStubbedEventClient

- (void)eventListWithParameters:(NSDictionary*)parameters
                        success:(void (^)(NSArray<ZNGEvent *> * events, ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure
{
    
}

- (void)eventWithId:(NSString*)eventId
            success:(void (^)(ZNGEvent * event, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure
{
    
}

- (void)postInternalNote:(NSString *)note
               toContact:(ZNGContact *)contact
                 success:(void (^)(ZNGEvent * note, ZNGStatus * status))success
                 failure:(void (^)(ZNGError * error))failure
{
    
}

@end
