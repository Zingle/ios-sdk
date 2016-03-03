//
//  ZNGLabelClientTests.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/10/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGLabelClient.h"

@interface ZNGLabelClientTests : ZNGBaseTests

@end

@implementation ZNGLabelClientTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - GET methods

- (void)testLabelList
{
    [ZNGLabelClient labelListWithParameters:nil withServiceId:[self serviceId] success:^(NSArray *contactFields, ZNGStatus *status) {
        
        XCTAssert(contactFields != nil, @"Labels are nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testLabelList"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testLabelList"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testLabelList"];
}

- (void)testLabelById
{
    [ZNGLabelClient labelWithId:@"d5a7bb87-6c55-4334-bece-952f70522fb5" withServiceId:[self serviceId] success:^(ZNGLabel *label, ZNGStatus *status) {
        
        XCTAssert(label != nil, @"Label is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testLabelById"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testLabelById"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testLabelById"];
}

#pragma mark - POST and DELETE methods

- (void)testCreateAndDeleteLabel
{
    ZNGLabel *label = [[ZNGLabel alloc] init];
    label.displayName = @"iOS Test Label";
    label.backgroundColor = @"#ff0000";
    label.textColor = @"#ffffff";
    
    [ZNGLabelClient saveLabel:label withServiceId:[self serviceId] success:^(ZNGLabel *label, ZNGStatus *status) {
        
        XCTAssert(label != nil, @"Label is nil!");
        
        [ZNGLabelClient deleteLabelWithId:label.labelId withServiceId:[self serviceId] success:^(ZNGStatus *status) {
            
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteLabel"];
            
        } failure:^(ZNGError *error) {
            
            XCTFail(@"fail: \"%@\"", [error description]);
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteLabel"];
        }];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteLabel"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testCreateAndDeleteLabel"];
}

#pragma mark - PUT methods

- (void)testUpdateLabel
{
    NSDictionary *params = @{ @"background_color" : @"#0000ff" };
    [ZNGLabelClient updateLabelWithId:@"069c609b-7e53-4f08-842e-fc2a9d1d5c76" withServiceId:[self serviceId] withParameters:params success:^(ZNGLabel *label, ZNGStatus *status) {
                
        XCTAssert(label != nil, @"Updated label is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateLabel"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateLabel"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testUpdateLabel"];
}

@end
