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

static NSString * const ColoProductionApiPath = @"https://api-1.zingle.medallia.com/v1";
static NSString * const ColoProductionApiV2Path = @"https://api-1.zingle.medallia.com/v2";
static NSString * const ColoProductionAuthPath = @"https://app-1.zingle.medallia.com/auth";
static NSString * const ColoProductionSocketPath = @"https://socket-1.zingle.medallia.com/";
static NSString * const ColoProductionAppPath = @"https://app-1.zingle.medallia.com/";

static NSString * const QaApiPath = @"https://qa-api.zingle.me/v1";
static NSString * const QaApiV2Path = @"https://qa-app.zingle.me/v2";
static NSString * const QaAuthPath = @"https://qa-app.zingle.me/auth";
static NSString * const QaSocketPath = @"https://qa-socket.zingle.me/";
static NSString * const QaAppPath = @"https://qa-app.zingle.me/";

static NSString * const StagePatternApiPath = @"https://api-3.zingle.den.medallia.com/v1";
static NSString * const StagePatternApiV2Path = @"https://api-3.zingle.den.medallia.com/v2";
static NSString * const StagePatternAuthPath = @"https://app-3.zingle.den.medallia.com/auth";
static NSString * const StagePatternSocketPath = @"https://socket-3.zingle.den.medallia.com/";
static NSString * const StagePatternAppPath = @"https://app-3.zingle.den.medallia.com/";

static NSString * const NonZinglePath = @"https://something-else.clownpenis.fart/";

static NSString * const ManySubdomainsInstanceName = @"things.stuff.places";
static NSString * const ManySubdomainsApiPath = @"https://api.things.stuff.places.zingle.me/v1";
static NSString * const ManySubdomainsSocketPath = @"https://app.things.stuff.places.zingle.me:8000/";
static NSString * const ManySubdomainsAppPath = @"https://app.things.stuff.places.zingle.me/";


@interface TestURLParsing : XCTestCase

@end


// Publicly define an interface for some private, internal methods to NSURL+Zingle
@interface NSURL (PrivateZingleURLMethods)
- (NSString *)_zingleServerPrefix;
- (NSString *)_zingleServerSuffix;
- (NSString *)_multipleSubdomainInstanceName;
@end


@implementation TestURLParsing

- (void) testProductionUrlDetection
{
    NSURL * nonZingleUrl = [NSURL URLWithString:NonZinglePath];
    NSURL * nonProductionApi = [NSURL URLWithString:CiApiPath];
    NSURL * nonProductionWebApp = [NSURL URLWithString:CiAppPath];

    NSURL * nonProductionQaApi = [NSURL URLWithString:QaApiPath];
    NSURL * nonProductionQaWebApp = [NSURL URLWithString:QaAppPath];
    NSURL * nonProductionStageApi = [NSURL URLWithString:StagePatternApiPath];
    NSURL * nonProductionStageWebApp = [NSURL URLWithString:StagePatternAppPath];

    NSURL * productionApi = [NSURL URLWithString:ProductionApiPath];
    NSURL * productionWebApp = [NSURL URLWithString:ProductionAppPath];
    NSURL * coloProductionApi = [NSURL URLWithString:ColoProductionApiPath];
    NSURL * coloProductionWebApp = [NSURL URLWithString:ColoProductionAppPath];
    
    
    XCTAssertFalse([nonZingleUrl isZingleProduction], @"`isZingleProduction` should be `NO` for a non-Zingle URL");
    XCTAssertFalse([nonProductionApi isZingleProduction], @"`isZingleProduction` should be `NO` for a non production API URL");
    XCTAssertFalse([nonProductionWebApp isZingleProduction], @"`isZingleProduction` should be `NO` for a non production web app URL");

    XCTAssertFalse([nonProductionQaApi isZingleProduction], @"`isZingleProduction` should be `NO` for a QA API URL");
    XCTAssertFalse([nonProductionQaWebApp isZingleProduction], @"`isZingleProduction` should be `NO` for a QA web app URL");
    XCTAssertFalse([nonProductionStageApi isZingleProduction], @"`isZingleProduction` should be `NO` for a staging API URL");
    XCTAssertFalse([nonProductionStageWebApp isZingleProduction], @"`isZingleProduction` should be `NO` for a staging web app URL");

    XCTAssertTrue([productionApi isZingleProduction], @"`isZingleProduction` should be `YES` for a production API URL");
    XCTAssertTrue([productionWebApp isZingleProduction], @"`isZingleProduction` should be `YES` for a production web app URL");
    XCTAssertTrue([coloProductionApi isZingleProduction], @"`isZingleProduction` should be `YES` for a COLO production API URL");
    XCTAssertTrue([coloProductionWebApp isZingleProduction], @"`isZingleProduction` should be `YES` for a COLO production web app URL");
}

- (void) testPrefixDetection
{
    NSURL * production = [NSURL URLWithString:ProductionApiPath];
    NSURL * coloProductionApi = [NSURL URLWithString:ColoProductionApiPath];
    NSURL * stage = [NSURL URLWithString:StagePatternApiPath];
    NSURL * ci = [NSURL URLWithString:CiApiPath];
    NSURL * manySubdomains = [NSURL URLWithString:ManySubdomainsApiPath];
    
    XCTAssertNil([production _zingleServerPrefix], @"Production naming should return `nil` for `_zingleServerPrefix`");
    XCTAssertNil([coloProductionApi _zingleServerPrefix], @"Newer production naming should return `nil` for `_zingleServerPrefix`");
    XCTAssertNil([stage _zingleServerPrefix], @"Newer stage instance naming should return `nil` for `_zingleServerPrefix`");
    XCTAssertEqualObjects([ci _zingleServerPrefix], @"ci", @"Hyphenated instance should return proper Zingle instance name");
    XCTAssertNil([manySubdomains _zingleServerPrefix], @"Newer, non-hyphenated instance naming should return `nil` for `_zingleServerPrefix`");
}

- (void) testSuffixDetection
{
    NSURL * production = [NSURL URLWithString:ProductionApiPath];
    NSURL * coloProductionApi = [NSURL URLWithString:ColoProductionApiPath];
    NSURL * stage = [NSURL URLWithString:StagePatternApiPath];
    NSURL * ci = [NSURL URLWithString:CiApiPath];
    NSURL * manySubdomains = [NSURL URLWithString:ManySubdomainsApiPath];
    
    XCTAssertNil([production _zingleServerSuffix], @"Production naming should return `nil` for `_zingleServerSuffix`");
    XCTAssertEqualObjects([coloProductionApi _zingleServerSuffix], @"1", @"Newer production naming should return proper suffix");
    XCTAssertEqualObjects([stage _zingleServerSuffix], @"3", @"Newer stage instance naming should return proper suffix");
    XCTAssertNil([ci _zingleServerSuffix], @"Hyphenated instance should return `nil` for `_zingleServerSuffix`");
    XCTAssertNil([manySubdomains _zingleServerSuffix], @"Newer, non-hyphenated instance naming should return `nil` for `_zingleServerPrefix`");
}


- (void) testSubdomainDetection
{
    NSURL * production = [NSURL URLWithString:ProductionApiPath];
    NSURL * coloProduction = [NSURL URLWithString:ColoProductionApiPath];
    NSURL * stage = [NSURL URLWithString:StagePatternApiPath];
    NSURL * ci = [NSURL URLWithString:CiApiPath];
    NSURL * manySubdomains = [NSURL URLWithString:ManySubdomainsApiPath];

    XCTAssertNil([production _multipleSubdomainInstanceName], @"Production URL should return `nil` for `_multipleSubdomainInstanceName`");
    XCTAssertNil([coloProduction _multipleSubdomainInstanceName], @"Newer production URL should return `nil` for `_multipleSubdomainInstanceName`");
    XCTAssertNil([stage _multipleSubdomainInstanceName], @"Stage URL should return `nil` for `_multipleSubdomainInstanceName`");
    XCTAssertNil([ci _multipleSubdomainInstanceName], @"CI URL (old, hyphenated-style instance naming) should return `nil` for `_multipleSubdomainInstanceName`");
    XCTAssertEqualObjects([manySubdomains _multipleSubdomainInstanceName], ManySubdomainsInstanceName, @"Instance name should be resolved correctly from a multiple subdomain instance, e.g. `qa05.denver` for `api.qa05.denver.zingle.me`)");
}

- (void) testApiFromAppUrl
{
    NSURL * url = [NSURL URLWithString:ProductionAppPath];
    NSURL * hopefullyV1 = [url apiUrlV1];
    NSURL * actuallyV1 = [NSURL URLWithString:ProductionApiPath];
    XCTAssertEqualObjects(hopefullyV1, actuallyV1, @"`apiUrlV1` should return correct URL from production web app URL");
    
    NSURL * urlNewProd = [NSURL URLWithString:ColoProductionAppPath];
    NSURL * sutNewProdV1 = [urlNewProd apiUrlV1];
    NSURL * actualNewProdV1 = [NSURL URLWithString:ColoProductionApiPath];
    XCTAssertEqualObjects(sutNewProdV1, actualNewProdV1, @"`apiUrlV1` should return correct URL from new production web app URL");
    
    NSURL * urlHypen = [NSURL URLWithString:QaAppPath];
    NSURL * sutHyphenV1 = [urlHypen apiUrlV1];
    NSURL * actualHyphenV1 = [NSURL URLWithString:QaApiPath];
    XCTAssertEqualObjects(sutHyphenV1, actualHyphenV1, @"`apiUrlV1` should return correct URL from QA web app URL");

    NSURL * urlStage = [NSURL URLWithString:StagePatternAppPath];
    NSURL * sutStageV1 = [urlStage apiUrlV1];
    NSURL * actualStageV1 = [NSURL URLWithString:StagePatternApiPath];
    XCTAssertEqualObjects(sutStageV1, actualStageV1, @"`apiUrlV1` should return correct URL from Stage web app URL");
}

- (void) testApiPathIdentity
{
    NSURL * url = [NSURL URLWithString:ProductionApiPath];
    NSURL * hopefullySame = [url apiUrlV1];
    XCTAssertEqualObjects(hopefullySame, url, @"`apiUrlV1` should be an identity function when given a V1 API URL");

    NSURL * urlStage = [NSURL URLWithString:StagePatternApiPath];
    NSURL * hopefullySameStage = [urlStage apiUrlV1];
    XCTAssertEqualObjects(hopefullySameStage, urlStage, @"`apiUrlV1` should be an identity function when given a V1 Stage API URL");
}

- (void) testV2ApiPathFromV1
{
    NSURL * v1 = [NSURL URLWithString:ProductionApiPath];
    NSURL * hopefullyV2 = [v1 apiUrlV2];
    NSURL * actuallyV2 = [NSURL URLWithString:ProductionApiV2Path];
    XCTAssertEqualObjects(hopefullyV2, actuallyV2, @"`apiUrlV2` should return V2 API URL");

    NSURL * urlStage = [NSURL URLWithString:StagePatternApiPath];
    NSURL * sutStageV2 = [urlStage apiUrlV2];
    NSURL * actualStageV2 = [NSURL URLWithString:StagePatternApiV2Path];
    XCTAssertEqualObjects(sutStageV2, actualStageV2, @"`apiUrlV2` should return correct URL from Stage V1 API URL");
}

- (void) testAuthPathFromApiPath
{
    NSURL * apiUrl = [NSURL URLWithString:ProductionApiPath];
    NSURL * expectedAuthUrl = [NSURL URLWithString:ProductionAuthPath];
    XCTAssertEqualObjects([apiUrl authUrl], expectedAuthUrl, @"Calling `authUrl` should return the coresponding auth URL from the production API URL");
    
    NSURL * coloApiUrl = [NSURL URLWithString:ColoProductionApiPath];
    NSURL * expectedColoAuthUrl = [NSURL URLWithString:ColoProductionAuthPath];
    XCTAssertEqualObjects([coloApiUrl authUrl], expectedColoAuthUrl, @"Calling `authUrl` should return the coresponding auth URL from the COLO API URL");
    
    NSURL * apiCiUrl = [NSURL URLWithString:CiApiPath];
    NSURL * expectedCiAuthUrl = [NSURL URLWithString:CiAuthPath];
    XCTAssertEqualObjects([apiCiUrl authUrl], expectedCiAuthUrl, @"Calling `authUrl` should return the coresponding auth URL from the CI API URL");
}

 - (void) testSocketUrlFromApi
{
    NSURL * apiUrl = [NSURL URLWithString:ProductionApiPath];
    NSURL * expectedSocketUrl = [NSURL URLWithString:ProductionSocketPath];
    XCTAssertEqualObjects([apiUrl socketUrl], expectedSocketUrl, @"`socketUrl` from API URL should produce %@", expectedSocketUrl);

    NSURL * coloApiUrl = [NSURL URLWithString:ColoProductionApiPath];
    NSURL * expectedColoSocketUrl = [NSURL URLWithString:ColoProductionSocketPath];
    XCTAssertEqualObjects([coloApiUrl socketUrl], expectedColoSocketUrl, @"Calling `socketUrl` should return the coresponding socket URL from the COLO API URL");

    NSURL * urlStage = [NSURL URLWithString:StagePatternApiPath];
    NSURL * sutStageSocket = [urlStage socketUrl];
    NSURL * actualStageSocketUrl = [NSURL URLWithString:StagePatternSocketPath];
    XCTAssertEqualObjects(sutStageSocket, actualStageSocketUrl, @"`socketUrl` should return correct socket URL from Stage V1 API URL");

    NSURL * apiCiUrl = [NSURL URLWithString:CiApiPath];
    NSURL * expectedCiSocketUrl = [NSURL URLWithString:CiSocketPath];
    XCTAssertEqualObjects([apiCiUrl socketUrl], expectedCiSocketUrl, @"`socketUrl` from API URL should produce %@", expectedCiSocketUrl);
}

- (void) testManySubdomainHosts
{
    NSURL * webApp = [NSURL URLWithString:ManySubdomainsAppPath];
    NSURL * v1Api = [NSURL URLWithString:ManySubdomainsApiPath];
    NSURL * socket = [NSURL URLWithString:ManySubdomainsSocketPath];
    
    XCTAssertEqualObjects([webApp apiUrlV1], v1Api, @"`apiUrlV1` should return full v1 API URL from a web app URL with many subdomains");
    XCTAssertEqualObjects([webApp socketUrl], socket, @"`apiUrlV1` should return full v1 API URL from a web app URL with many subdomains");
}

- (void) testWebAppUrlFromComplexApiUrl
{
    NSURL * complexApiUrl = [NSURL URLWithString:@"https://api.zingle.me/things/stuff?moreThings=please"];
    NSURL * hopefullyWebAppUrl = [complexApiUrl webAppUrl];
    NSURL * actuallyWebAppUrl = [NSURL URLWithString:ProductionAppPath];
    XCTAssertEqualObjects(hopefullyWebAppUrl, actuallyWebAppUrl, @"`appUrl` should return a web app URL from a complex API URL");
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


@end
