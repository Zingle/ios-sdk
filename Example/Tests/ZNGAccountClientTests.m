//
//  ZNGAccountClientTests.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/4/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGAccountClient.h"

@interface ZNGAccountClientTests : ZNGBaseTests

@end

@implementation ZNGAccountClientTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - GET methods

- (void)testAccountList
{
    [ZNGAccountClient accountListWithParameters:nil success:^(NSArray *accounts, ZNGStatus *status) {
        
        XCTAssert(accounts != nil, @"Accounts are nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testAccountList"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testAccountList"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testAccountList"];
}

- (void)testAccountById
{
    [ZNGAccountClient accountWithId:[self accountId] success:^(ZNGAccount *account, ZNGStatus *status) {
        
        XCTAssert(account != nil, @"Account is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testAccountById"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testAccountById"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testAccountById"];
}

@end
