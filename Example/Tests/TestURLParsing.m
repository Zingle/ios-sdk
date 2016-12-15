//
//  TestURLParsing.m
//  ZingleSDK
//
//  Created by Jason Neel on 12/15/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSURL+Zingle.h"

@interface TestURLParsing : XCTestCase

@end

@implementation TestURLParsing

- (void) testProductionAPIURL
{
    NSString * path = @"https://api.zingle.me/";
    NSURL * url = [NSURL URLWithString:path];
    NSString * prefix = [url zingleServerPrefix];
    XCTAssertEqualObjects(prefix, @"", @"Server prefix for api.zingle.me should return an empty string");
}

- (void) testQAAPIURL
{
    NSString * path = @"https://qa-api.zingle.me/";
    NSURL * url = [NSURL URLWithString:path];
    NSString * prefix = [url zingleServerPrefix];
    XCTAssertEqualObjects(prefix, @"qa", @"Server prefix for qa-api.zingle.me should be \"qa\"");
}

- (void) testProductionComplexURL
{
    NSString * path = @"https://api.zingle.me/things/stuff?moreThings=please";
    NSURL * url = [NSURL URLWithString:path];
    NSString * prefix = [url zingleServerPrefix];
    XCTAssertEqualObjects(prefix, @"", @"Server prefix for api.zingle.me, even with additional path information and a query string, should return an empty string");
}

- (void) testNonZingleURLReturnsNil
{
    NSString * path = @"https://something-else.clownpenis.fart/";
    NSURL * url = [NSURL URLWithString:path];
    NSString * prefix = [url zingleServerPrefix];
    XCTAssertNil(prefix, @"Server prefix for a non-Zingle URL should return nil");
}

@end
