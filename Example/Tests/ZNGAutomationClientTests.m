//
//  ZNGAutomationClientTests.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/11/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGAutomationClient.h"

@interface ZNGAutomationClientTests : ZNGBaseTests

@end

@implementation ZNGAutomationClientTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - GET methods

- (void)testAutomationList
{
    [ZNGAutomationClient automationListWithParameters:nil withServiceId:[self serviceId] success:^(NSArray *automations, ZNGStatus *status) {
        
        XCTAssert(automations != nil, @"Automations are nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testAutomationsList"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testAutomationsList"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testAutomationsList"];
}

- (void)testAutomationById
{
    [ZNGAutomationClient automationWithId:@"3a2a029d-c67a-4c14-a679-e29eaab5616b" withServiceId:[self serviceId] success:^(ZNGAutomation *automation, ZNGStatus *status) {
        
        XCTAssert(automation != nil, @"Automation is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testAutomationById"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testAutomationById"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testAutomationById"];
}

#pragma mark - PUT methods

- (void)testUpdateAutomation
{
    NSDictionary *params = @{ @"status" : @"active" };
    [ZNGAutomationClient updateAutomationWithId:@"3a2a029d-c67a-4c14-a679-e29eaab5616b" withServiceId:[self serviceId] withParameters:params success:^(ZNGAutomation *automation, ZNGStatus *status) {
                
        XCTAssert(automation != nil, @"Updated automation is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateAutomation"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateAutomation"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testUpdateAutomation"];
}

@end
