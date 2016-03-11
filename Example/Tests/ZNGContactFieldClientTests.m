//
//  ZNGContactFieldClientTests.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/10/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGContactFieldClient.h"

@interface ZNGContactFieldClientTests : ZNGBaseTests

@end

@implementation ZNGContactFieldClientTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - GET methods

- (void)testContactFieldList
{
    [ZNGContactFieldClient contactFieldListWithParameters:nil withServiceId:[self serviceId] success:^(NSArray *contactFields, ZNGStatus *status) {
        
        XCTAssert(contactFields != nil, @"ContactFields are nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testContactFieldList"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testContactFieldList"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testContactFieldList"];
}

- (void)testContactFieldById
{
    [ZNGContactFieldClient contactFieldWithId:@"d1a15384-9ba2-41b4-a02e-331a8a080e38" withServiceId:[self serviceId] success:^(ZNGContactField *contactField, ZNGStatus *status) {
        
        XCTAssert(contactField != nil, @"ContactField is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testContactFieldById"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testContactFieldById"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testContactFieldById"];
}

#pragma mark - POST and DELETE methods

- (void)testCreateAndDeleteContactField
{
    ZNGContactField *contactField = [[ZNGContactField alloc] init];
    NSUInteger rand = arc4random_uniform(1000000);
    contactField.displayName = [NSString stringWithFormat:@"iOS Test Contact Field - %lu", (unsigned long)rand];
    
    [ZNGContactFieldClient saveContactField:contactField withServiceId:[self serviceId] success:^(ZNGContactField *contactField, ZNGStatus *status) {
        
        XCTAssert(contactField != nil, @"ContactField service is nil!");
        
        [ZNGContactFieldClient deleteContactFieldWithId:contactField.contactFieldId withServiceId:[self serviceId] success:^(ZNGStatus *status) {
            
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteContactField"];
            
        } failure:^(ZNGError *error) {
            
            XCTFail(@"fail: \"%@\"", [error description]);
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteContactField"];
        }];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteContactField"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testCreateAndDeleteContactField"];
}

#pragma mark - PUT methods

- (void)testUpdateContactField
{
    [ZNGContactFieldClient updateContactFieldWithId:@"c0454244-445f-4b2f-87f3-e06ad62ce9c7" withServiceId:[self serviceId] withParameters:nil success:^(ZNGContactField *contactField, ZNGStatus *status) {
        
        XCTAssert(contactField != nil, @"Updated contactField is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateContactField"];

    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateContactField"];
    }];

    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testUpdateContactField"];
}

@end
