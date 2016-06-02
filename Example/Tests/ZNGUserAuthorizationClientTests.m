//
//  ZNGUserAuthorizationClientTests.m
//  ZingleSDK
//
//  Created by Robert Harrison on 5/24/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGAsyncSemaphor.h"
#import "ZNGUserAuthorizationClient.h"
#import "ZNGuserAuthorization.h"

@interface ZNGUserAuthorizationClientTests : XCTestCase

@end

@implementation ZNGUserAuthorizationClientTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - GET methods

- (void)testUserAuthorizationAccount {
    
    // Use a token and key for a user with type "account".
    NSString *key = [[[NSProcessInfo processInfo] environment] objectForKey:@"TEST_KEY"];
    NSString *token = [[[NSProcessInfo processInfo] environment] objectForKey:@"TEST_TOKEN"];
    
    ZingleSDK *sdk = [ZingleSDK sharedSDK];
    [sdk setToken:token andKey:key forDebugMode:YES];
    
    // Test
    
    [ZNGUserAuthorizationClient userAuthorizationWithSuccess:^(ZNGUserAuthorization *userAuthorization, ZNGStatus *status) {
        
        XCTAssert(userAuthorization != nil, @"UserAuthorization is nil!");
        
        XCTAssertNotNil(userAuthorization.authorizationClass, @"userAuthorization.authorizationClass is nil!");
        XCTAssertTrue([userAuthorization.authorizationClass isEqualToString:@"account"], @"userAuthorization.authorizationClass does not equal account!");
        
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUserAuthorizationAccount"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUserAuthorizationAccount"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testUserAuthorizationAccount"];
    
}

- (void)testUserAuthorizationContact {
    
    // Use a token and key for a user with type "contact".
    NSString *key = [[[NSProcessInfo processInfo] environment] objectForKey:@"TEST_CONTACT_KEY"];
    NSString *token = [[[NSProcessInfo processInfo] environment] objectForKey:@"TEST_CONTACT_TOKEN"];
    
    ZingleSDK *sdk = [ZingleSDK sharedSDK];
    [sdk setToken:token andKey:key forDebugMode:YES];
    
    // Test
    
    [ZNGUserAuthorizationClient userAuthorizationWithSuccess:^(ZNGUserAuthorization *userAuthorization, ZNGStatus *status) {
        
        XCTAssert(userAuthorization != nil, @"UserAuthorization is nil!");
        
        XCTAssertNotNil(userAuthorization.authorizationClass, @"userAuthorization.authorizationClass is nil!");
        XCTAssertTrue([userAuthorization.authorizationClass isEqualToString:@"contact"], @"userAuthorization.authorizationClass does not equal contact!");
        
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUserAuthorizationContact"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUserAuthorizationContact"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testUserAuthorizationContact"];
    
}

@end
