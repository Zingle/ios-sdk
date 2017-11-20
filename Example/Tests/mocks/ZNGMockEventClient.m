//
//  ZNGMockEventClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 3/7/17.
//  Copyright © 2017 Zingle. All rights reserved.
//

#import "ZNGMockEventClient.h"
#import <ZingleSDK/ZNGEvent.h>

@implementation ZNGMockEventClient

- (void)eventListWithParameters:(NSDictionary*)parameters
                        success:(void (^)(NSArray<ZNGEvent *> * events, ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (success) {
            // Keep things simple for this mock by only returning the most recent page
            ZNGStatus * status = [[ZNGStatus alloc] init];
            status.totalRecords = [self.events count];
            status.pageSize = 25;
            status.totalPages = [self.events count] / status.pageSize + 1;
            status.page = 1;
            
            NSArray<ZNGEvent *> * results = nil;
            
            if ([self.events count] > status.pageSize) {
                results = [self.events subarrayWithRange:NSMakeRange([self.events count] - status.pageSize, status.pageSize)];
            } else {
                results = self.events;
            }
            
            success(results, status);
        }
    });
}

- (void)eventWithId:(NSString*)eventId
            success:(void (^)(ZNGEvent * event, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (success) {
            ZNGEvent * result = [self _eventWithId:eventId];
            ZNGStatus * status = [[ZNGStatus alloc] init];
            NSInteger zeroOrOne = (NSInteger)(result != nil);
            
            status.totalPages = zeroOrOne;
            status.totalRecords = zeroOrOne;
            status.page = zeroOrOne;
            status.pageSize = zeroOrOne;
            
            success(result, status);
        }
    });
}

- (ZNGEvent *) _eventWithId:(NSString *)eventId
{
    NSUInteger index = [self.events indexOfObjectPassingTest:^BOOL(ZNGEvent * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.eventId isEqualToString:eventId];
    }];
    
    if (index != NSNotFound) {
        return self.events[index];
    }
    
    return nil;
}

- (void)postInternalNote:(NSString *)note
               toContact:(ZNGContact *)contact
                 success:(void (^)(ZNGEvent * note, ZNGStatus * status))success
                 failure:(void (^)(ZNGError * error))failure
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (success) {
            success(nil, nil);
        }
    });
}

@end
