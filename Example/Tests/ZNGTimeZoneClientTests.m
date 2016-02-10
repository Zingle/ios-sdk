//
//  ZNGTimeZoneClientTests.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/5/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGTimeZoneClient.h"

@interface ZNGTimeZoneClientTests : ZNGBaseTests

@end

@implementation ZNGTimeZoneClientTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - GET methods

- (void)testTimeZoneList
{
    [ZNGTimeZoneClient timeZoneListWithSuccess:^(NSArray *timeZones) {
        
        XCTAssert(timeZones != nil, @"Time zones are nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testTimeZonesList"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testTimeZonesList"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testTimeZonesList"];
}

@end
