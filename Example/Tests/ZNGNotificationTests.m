//
//  ZNGNotificationTests.m
//  ZingleSDK
//
//  Created by Ryan Farley on 4/5/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGNotificationsClient.h"

@interface ZNGNotificationTests : ZNGBaseTests

@end

@implementation ZNGNotificationTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testRegisterForNotifications {
    
    [ZNGNotificationsClient registerForNotificationsWithDeviceId:@"testdeviceID" withServiceIds:@[[self serviceId]] success:^(ZNGStatus *status) {
        
        XCTAssert(status.statusCode == 200);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testRegisterForNotifications"];
    } failure:^(ZNGError *error) {
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testRegisterForNotifications"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testRegisterForNotifications"];
}

- (void)testUnregisterForNotifications {

    [ZNGNotificationsClient unregisterForNotificationsWithDeviceId:@"testdeviceID" success:^(ZNGStatus *status) {
        
        XCTAssert(status.statusCode == 200);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUnregisterForNotifications"];
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUnregisterForNotifications"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testUnregisterForNotifications"];
}

@end
