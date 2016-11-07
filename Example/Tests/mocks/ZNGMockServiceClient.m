//
//  ZNGMockServiceClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 10/27/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import "ZNGMockServiceClient.h"

@implementation ZNGMockServiceClient

- (ZNGStatus *)status
{
    ZNGStatus * status = [[ZNGStatus alloc] init];
    status.statusCode = 200;
    status.totalPages = 1;
    status.totalRecords = [self.services count];
    return status;
}

- (void) serviceListUnderAccountId:(NSString *)accountId
                           success:(void (^)(NSArray* services, ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure
{
    if (success == nil) {
        return;
    }
    
    NSMutableArray<ZNGService *> * services = [[NSMutableArray alloc] initWithCapacity:[self.services count]];
    
    for (ZNGService * service in self.services) {
        if ([service.account.accountId isEqualToString:accountId]) {
            [services addObject:service];
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ZNGStatus * status = [[ZNGStatus alloc] init];
        status.statusCode = 200;
        status.totalPages = 1;
        status.page = 1;
        status.totalRecords = [services count];
        
        success(services, status);
    });
}

- (void)serviceWithId:(NSString*)serviceId
              success:(void (^)(ZNGService* service, ZNGStatus* status))success
              failure:(void (^)(ZNGError* error))failure
{
    [self.serviceRequestedExpectation fulfill];
    self.serviceRequestedExpectation = nil;
    
    if (self.throwExceptionOnAnyServiceRequest) {
        [NSException raise:@"Refreshed with do not refresh flag set in mock object" format:@"Service was requested with the triggerTestFailOnAnyServiceRequest flag set to YES :("];
    }
    
    if (success == nil) {
        return;
    }
    
    ZNGService * matchingService = nil;
    
    for (ZNGService * service in self.services) {
        if ([service.serviceId isEqualToString:serviceId]) {
            matchingService = service;
            break;
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ZNGStatus * status = [[ZNGStatus alloc] init];
        status.statusCode = 200;
        status.totalPages = 1;
        status.totalRecords = (BOOL)matchingService;
        status.page = 1;
        
        success(matchingService, status);
    });
}

@end
