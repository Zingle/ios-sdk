//
//  ZNGAccountPlanTests.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/5/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGAccountPlanClient.h"

@interface ZNGAccountPlanClientTests : ZNGBaseTests


@end

@implementation ZNGAccountPlanClientTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - GET methods

- (void)testPlanList
{
    [ZNGAccountPlanClient accountPlanListWithAccountId:[self accountId] withParameters:nil success:^(NSArray *plans) {
        
        XCTAssert(plans != nil, @"Plans are nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testPlanList"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testPlanList"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testPlanList"];
}

- (void)testPlanById
{
    [ZNGAccountPlanClient accountPlanWithAccountId:[self accountId] withPlanId:[self planId] success:^(ZNGAccountPlan *plan) {
        
        XCTAssert(plan != nil, @"Plan is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testPlanById"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testPlanById"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testPlanById"];
}

@end
