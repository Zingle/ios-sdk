//
//  ZNGTemplateClientTests.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/10/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGTemplateClient.h"

@interface ZNGTemplateClientTests : ZNGBaseTests

@end

@implementation ZNGTemplateClientTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - GET methods

- (void)testTemplateList
{
    [ZNGTemplateClient templateListWithParameters:nil withServiceId:[self serviceId] success:^(NSArray *templ, ZNGStatus *status) {
        
        XCTAssert(templ != nil, @"Templates are nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testTemplateList"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testTemplateList"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testTemplateList"];
}

- (void)testTemplateById
{
    [ZNGTemplateClient templateWithId:@"f505dfc5-9314-41c6-b36a-de77f2c8f72b" withServiceId:[self serviceId] success:^(ZNGTemplate *templ, ZNGStatus *status) {
        
        XCTAssert(templ != nil, @"Template is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testTemplateById"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testTemplateById"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testTemplateById"];
}

#pragma mark - POST and DELETE methods

- (void)testCreateAndDeleteTemplate
{
    ZNGTemplate *template = [[ZNGTemplate alloc] init];
    template.type = @"general";
    template.body = @"iOS Test Template";
    template.displayName = @"iOS Test Template";
    
    [ZNGTemplateClient saveTemplate:template withServiceId:[self serviceId] success:^(ZNGTemplate *templ, ZNGStatus *status) {
        
        XCTAssert(template != nil, @"Label is nil!");
        
        [ZNGTemplateClient deleteTemplateWithId:template.templateId withServiceId:[self serviceId] success:^(ZNGStatus *status) {
            
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteTemplate"];
            
        } failure:^(ZNGError *error) {
            
            XCTFail(@"fail: \"%@\"", [error description]);
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteTemplate"];
        }];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteTemplate"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testCreateAndDeleteTemplate"];
}

#pragma mark - PUT methods

- (void)testUpdateTemplate
{
    NSDictionary *params = @{ @"body" : @"This is a test body." };
    [ZNGTemplateClient updateTemplateWithId:@"f505dfc5-9314-41c6-b36a-de77f2c8f72b" withServiceId:[self serviceId] withParameters:params success:^(ZNGTemplate *templ, ZNGStatus *status) {
        
        XCTAssert(templ != nil, @"Updated template is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateTemplate"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateTemplate"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testUpdateTemplate"];
}

@end
