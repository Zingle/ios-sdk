//
//  TestURLParsing.m
//  ZingleSDK
//
//  Created by Jason Neel on 12/15/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSURL+Zingle.h"

static NSString * const ProductionApiPath = @"https://api.zingle.me/v1";
static NSString * const ProductionAuthPath = @"https://app.zingle.me/auth";
static NSString * const ProductionSocketPath = @"https://socket.zingle.me/";
static NSString * const CiApiPath = @"https://ci-api.zingle.me/v1";
static NSString * const CiAuthPath = @"https://ci-app.zingle.me/auth";
static NSString * const CISocketPath = @"https://ci-app.zingle.me:8000/";
static NSString * const NonZinglePath = @"https://something-else.clownpenis.fart/";

@interface TestURLParsing : XCTestCase

@end

@implementation TestURLParsing

- (void) testProductionAPIURL
{
    NSURL * url = [NSURL URLWithString:ProductionApiPath];
    NSString * prefix = [url zingleServerPrefix];
    XCTAssertEqualObjects(prefix, @"", @"Server prefix for api.zingle.me should return an empty string");
}

- (void) testCIAPIURL
{
    NSURL * url = [NSURL URLWithString:CiApiPath];
    NSString * prefix = [url zingleServerPrefix];
    XCTAssertEqualObjects(prefix, @"ci", @"Server prefix for qa-api.zingle.me should be \"qa\"");
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
    NSURL * url = [NSURL URLWithString:NonZinglePath];
    NSString * prefix = [url zingleServerPrefix];
    XCTAssertNil(prefix, @"Server prefix for a non-Zingle URL should return nil");
}

- (void) testApiPathIdentity
{
    NSURL * url = [NSURL URLWithString:ProductionApiPath];
    XCTAssertEqualObjects(url, [url apiUrlV1], @"Calling `apiUrlV1` should be an identity operation on a v1 API URL");
}

- (void) testNonZingleUrlProducesNilZinglePaths
{
    NSURL * url = [NSURL URLWithString:NonZinglePath];
    XCTAssertNil([url apiUrlV1], @"Non-Zingle path should produce nil API path");
    XCTAssertNil([url authUrl], @"Non-Zingle path should produce nil auth path");
    XCTAssertNil([url socketUrl], @"Non-Zingle path should produce nil socket path");
}

- (void) testProductionAuthPathFromApiPath
{
    NSURL * apiUrl = [NSURL URLWithString:ProductionApiPath];
    NSURL * expectedAuthUrl = [NSURL URLWithString:ProductionAuthPath];
    
    XCTAssertEqualObjects([apiUrl authUrl], expectedAuthUrl, @"Calling `authUrl` should return the coresponding auth URL from the production API URL");
}

 - (void) testProductionSocketUrlFromApi
{
    NSURL * apiUrl = [NSURL URLWithString:ProductionApiPath];
    NSURL * expectedSocketUrl = [NSURL URLWithString:ProductionSocketPath];
    
    XCTAssertEqualObjects([apiUrl socketUrl], expectedSocketUrl, @"`socketUrl` from API URL should produce %@", expectedSocketUrl);
}

- (void) testCiAuthPathFromApiPath
{
    NSURL * apiUrl = [NSURL URLWithString:CiApiPath];
    NSURL * expectedAuthUrl = [NSURL URLWithString:CiAuthPath];
    
    XCTAssertEqualObjects([apiUrl authUrl], expectedAuthUrl, @"Calling `authUrl` should return the coresponding auth URL from the CI API URL");
}

- (void) testCiSocketPathFromApiPath
{
    NSURL * apiUrl = [NSURL URLWithString:CiApiPath];
    NSURL * expectedSocketUrl = [NSURL URLWithString:CISocketPath];
    
    XCTAssertEqualObjects([apiUrl socketUrl], expectedSocketUrl, @"`socketUrl` from API URL should produce %@", expectedSocketUrl);
}

@end
