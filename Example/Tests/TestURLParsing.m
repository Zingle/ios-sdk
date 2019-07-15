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
static NSString * const ProductionApiV2Path = @"https://api.zingle.me/v2";
static NSString * const ProductionAuthPath = @"https://app.zingle.me/auth";
static NSString * const ProductionSocketPath = @"https://socket.zingle.me/";
static NSString * const CiApiPath = @"https://ci-api.zingle.me/v1";
static NSString * const CiApiV2Path = @"https://ci-api.zingle.me/v2";
static NSString * const CiAuthPath = @"https://ci-app.zingle.me/auth";
static NSString * const CiSocketPath = @"https://ci-app.zingle.me:8000/";
static NSString * const NonZinglePath = @"https://something-else.clownpenis.fart/";

@interface TestURLParsing : XCTestCase

@end

@implementation TestURLParsing

- (void) testProductionApiUrl
{
    NSURL * url = [NSURL URLWithString:ProductionApiPath];
    NSString * prefix = [url zingleServerPrefix];
    XCTAssertEqualObjects(prefix, @"", @"Server prefix for api.zingle.me should return an empty string");
}

- (void) testCiApiUrl
{
    NSURL * url = [NSURL URLWithString:CiApiPath];
    NSString * prefix = [url zingleServerPrefix];
    XCTAssertEqualObjects(prefix, @"ci", @"Server prefix for qa-api.zingle.me should be \"qa\"");
}

- (void) testProductionComplexUrl
{
    NSString * path = @"https://api.zingle.me/things/stuff?moreThings=please";
    NSURL * url = [NSURL URLWithString:path];
    NSString * prefix = [url zingleServerPrefix];
    XCTAssertEqualObjects(prefix, @"", @"Server prefix for api.zingle.me, even with additional path information and a query string, should return an empty string");
}

- (void) testNonZingleUrlReturnsNil
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

- (void) testV2ApiPathFromV1
{
    NSURL * v1Url = [NSURL URLWithString:ProductionApiPath];
    NSURL * expectedV2Url = [NSURL URLWithString:ProductionApiV2Path];
    XCTAssertEqualObjects([v1Url apiUrlV2], expectedV2Url, @"Production V2 API URL should be calculable from V1");
    
    NSURL * ciV1Url = [NSURL URLWithString:CiApiPath];
    NSURL * expectedCiV2Url = [NSURL URLWithString:CiApiV2Path];
    XCTAssertEqualObjects([ciV1Url apiUrlV2], expectedCiV2Url, @"CI V2 API URL should be calculable from V1");
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
    NSURL * expectedSocketUrl = [NSURL URLWithString:CiSocketPath];
    
    XCTAssertEqualObjects([apiUrl socketUrl], expectedSocketUrl, @"`socketUrl` from API URL should produce %@", expectedSocketUrl);
}

@end
