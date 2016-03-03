//
//  ZNGServiceClientTests.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/5/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGServiceClient.h"

@interface ZNGServiceClientTests : ZNGBaseTests

@end

@implementation ZNGServiceClientTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - GET methods

- (void)testServiceList
{
    [ZNGServiceClient serviceListWithParameters:nil success:^(NSArray *services, ZNGStatus *status) {
        
        XCTAssert(services != nil, @"Services are nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testServicesList"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testServicesList"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testServicesList"];
}

- (void)testServiceById
{
    [ZNGServiceClient serviceWithId:[self serviceId] success:^(ZNGService *service, ZNGStatus *status) {
        
        XCTAssert(service != nil, @"Service is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testServiceById"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testServiceById"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testServiceById"];
}

#pragma mark - POST and DELETE methods

- (void)testCreateAndDeleteService
{
    [ZNGServiceClient saveService:[self service] success:^(ZNGService *service, ZNGStatus *status) {
        
        XCTAssert(service != nil, @"Created service is nil!");
        
        [ZNGServiceClient deleteServiceWithId:service.serviceId success:^(ZNGStatus *status) {
            
            XCTAssert(service != nil, @"Deleted service is nil!");
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteService"];
            
        } failure:^(ZNGError *error) {
            
            XCTFail(@"fail: \"%@\"", [error description]);
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteService"];
        }];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteService"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testCreateAndDeleteService"];
}

#pragma mark - PUT methods

- (void)testUpdateService
{
    [ZNGServiceClient updateServiceWithId:[self serviceId] withParameters:nil success:^(ZNGService *service, ZNGStatus *status) {
                
        XCTAssert(service != nil, @"Updated service is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateService"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateService"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testUpdateService"];
}

@end
