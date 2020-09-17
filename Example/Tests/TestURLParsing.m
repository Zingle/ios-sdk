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
static NSString * const ProductionAppPath = @"https://app.zingle.me/";
static NSString * const CiApiPath = @"https://ci-api.zingle.me/v1";
static NSString * const CiApiV2Path = @"https://ci-api.zingle.me/v2";
static NSString * const CiAuthPath = @"https://ci-app.zingle.me/auth";
static NSString * const CiSocketPath = @"https://ci-app.zingle.me:8000/";
static NSString * const CiAppPath = @"https://ci-app.zingle.me/";
static NSString * const NonZinglePath = @"https://something-else.clownpenis.fart/";
static NSString * const ManySubdomainsApiPath = @"https://api.things.stuff.places.zingle.me/v1";
static NSString * const ManySubdomainsSocketPath = @"https://app.things.stuff.places.zingle.me:8000/";
static NSString * const ManySubdomainsAppPath = @"https://app.things.stuff.places.zingle.me/";


@interface TestURLParsing : XCTestCase

@end


// Publicly define an interface for some private, internal methods to NSURL+Zingle
@interface NSURL (PrivateZingleURLMethods)
- (NSString *)_zingleServerPrefix;
- (NSString *)_multipleSubdomainInstanceName;
@end


@implementation TestURLParsing

- (void) testProductionUrlDetection
{
    NSURL * nonZingleUrl = [NSURL URLWithString:NonZinglePath];
    NSURL * nonProductionApi = [NSURL URLWithString:CiApiPath];
    NSURL * nonProductionWebApp = [NSURL URLWithString:CiAppPath];
    NSURL * productionApi = [NSURL URLWithString:ProductionApiPath];
    NSURL * productionWebApp = [NSURL URLWithString:ProductionAppPath];
    
    XCTAssertFalse([nonZingleUrl isZingleProduction], @"`isZingleProduction` should be `NO` for a non-Zingle URL");
    XCTAssertFalse([nonProductionApi isZingleProduction], @"`isZingleProduction` should be `NO` for a non production API URL");
    XCTAssertFalse([nonProductionWebApp isZingleProduction], @"`isZingleProduction` should be `NO` for a non production web app URL");
    XCTAssertTrue([productionApi isZingleProduction], @"`isZingleProduction` should be `YES` for a production API URL");
    XCTAssertTrue([productionWebApp isZingleProduction], @"`isZingleProduction` should be `YES` for a production web app URL");
}

- (void) testPrefixDetection
{
    NSURL * production = [NSURL URLWithString:ProductionApiPath];
    NSURL * ci = [NSURL URLWithString:CiApiPath];
    NSURL * manySubdomains = [NSURL URLWithString:ManySubdomainsApiPath];
    
    XCTAssertEqualObjects([production _zingleServerPrefix], @"", @"Production server prefix should be an empty string");
    XCTAssertEqualObjects([ci _zingleServerPrefix], @"ci", @"Hyphenated instance should return proper Zingle instance name");
    XCTAssertNil([manySubdomains _zingleServerPrefix], @"Newer, non-hyphenated instance naming should return `nil` for `_zingleServerPrefix`");
}

- (void) testApiFromAppUrl
{
    NSURL * url = [NSURL URLWithString:ProductionAppPath];
    NSURL * hopefullyV1 = [url apiUrlV1];
    NSURL * actuallyV1 = [NSURL URLWithString:ProductionApiPath];
    XCTAssertEqualObjects(hopefullyV1, actuallyV1, @"`apiUrlV1` should return correct URL from production web app URL");
}

- (void) testWebAppUrlFromComplexApiUrl
{
    NSURL * complexApiUrl = [NSURL URLWithString:@"https://api.zingle.me/things/stuff?moreThings=please"];
    NSURL * hopefullyWebAppUrl = [complexApiUrl webAppUrl];
    NSURL * actuallyWebAppUrl = [NSURL URLWithString:ProductionAppPath];
    XCTAssertEqualObjects(hopefullyWebAppUrl, actuallyWebAppUrl, @"`appUrl` should return a web app URL from a complex API URL");
}

- (void) testApiPathIdentity
{
    NSURL * url = [NSURL URLWithString:ProductionApiPath];
    NSURL * hopefullySame = [url apiUrlV1];
    XCTAssertEqualObjects(hopefullySame, url, @"`apiUrlV1` should be an identity function when given a V1 API URL");
}

- (void) testV2ApiPathFromV1
{
    NSURL * v1 = [NSURL URLWithString:ProductionApiPath];
    NSURL * hopefullyV2 = [v1 apiUrlV2];
    NSURL * actuallyV2 = [NSURL URLWithString:ProductionApiV2Path];
    XCTAssertEqualObjects(hopefullyV2, actuallyV2, @"`apiUrlV2` should return V2 API URL");
}

- (void) testNonZingleUrlProducesNilZinglePaths
{
    NSURL * url = [NSURL URLWithString:NonZinglePath];
    XCTAssertNil([url apiUrlV1], @"Non-Zingle path should produce nil API path");
    XCTAssertNil([url authUrl], @"Non-Zingle path should produce nil auth path");
    XCTAssertNil([url socketUrl], @"Non-Zingle path should produce nil socket path");
    XCTAssertNil([url apiUrlV2], @"Non-Zingle path should produce nil API V2 path");
    XCTAssertNil([url webAppUrl], @"Non-Zingle path should produce nil web app path");
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

- (void) testManySubdomainHosts
{
    NSURL * webApp = [NSURL URLWithString:ManySubdomainsAppPath];
    NSURL * v1Api = [NSURL URLWithString:ManySubdomainsApiPath];
    NSURL * socket = [NSURL URLWithString:ManySubdomainsSocketPath];
    
    XCTAssertEqualObjects([webApp apiUrlV1], v1Api, @"`apiUrlV1` should return full v1 API URL from a web app URL with many subdomains");
    XCTAssertEqualObjects([webApp socketUrl], socket, @"`apiUrlV1` should return full v1 API URL from a web app URL with many subdomains");
}

@end
