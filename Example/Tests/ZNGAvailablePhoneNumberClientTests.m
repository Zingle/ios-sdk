//
//  ZNGAvailablePhoneNumberClientTests.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/5/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGAvailablePhoneNumberClient.h"

@interface ZNGAvailablePhoneNumberClientTests : ZNGBaseTests

@end

@implementation ZNGAvailablePhoneNumberClientTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - GET methods

- (void)testAvailablePhoneNumberList
{
    [ZNGAvailablePhoneNumberClient availablePhoneNumberListForCountry:@"US" success:^(NSArray *availableNumbers) {
        
        XCTAssert(availableNumbers != nil, @"Available numbers are nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testAvailableNumbersList"];
        
    } failure:^(ZNGError *error) {
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testAvailableNumbersList"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testAvailableNumbersList"];
}

@end
