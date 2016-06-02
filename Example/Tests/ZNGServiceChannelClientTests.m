//
//  ZNGServiceChannelClientTests.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/8/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGServiceChannelClient.h"
#import "ZNGAvailablePhoneNumberClient.h"

@interface ZNGServiceChannelClientTests : ZNGBaseTests

@end

@implementation ZNGServiceChannelClientTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - GET methods

- (void)testServiceChannelById
{
    [ZNGServiceChannelClient serviceChannelWithId:[self serviceChannelId] withServiceId:[self serviceId] success:^(ZNGChannel *serviceChannel, ZNGStatus *status) {
        
        XCTAssert(serviceChannel != nil, @"Service channel is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testServiceChannelById"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testServiceChannelById"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testServiceChannelById"];
}

#pragma mark - POST and DELETE methods

- (void)testCreateAndDeleteServiceChannel
{
    [ZNGAvailablePhoneNumberClient availablePhoneNumberListForCountry:@"US" success:^(NSArray *availableNumbers, ZNGStatus *status) {
        
        ZNGAvailablePhoneNumber *number = [availableNumbers lastObject];
        
        [ZNGServiceChannelClient saveServiceChannel:[self serviceChannelWithValue:number.phoneNumber] withServiceId:[self serviceId] success:^(ZNGChannel *serviceChannel, ZNGStatus *status) {
            
            XCTAssert(serviceChannel != nil, @"Created service channel is nil!");
            
            [ZNGServiceChannelClient deleteServiceChannelWithId:serviceChannel.channelId withServiceId:[self serviceId] success:^(ZNGStatus *status) {
                
                XCTAssert(serviceChannel != nil, @"Deleted service channel is nil!");
                [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteServiceChannel"];
                
            } failure:^(ZNGError *error) {
                
                XCTFail(@"fail: \"%@\"", [error description]);
                [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteServiceChannel"];
            }];
            
        } failure:^(ZNGError *error) {
            
            XCTFail(@"fail: \"%@\"", [error description]);
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteServiceChannel"];
        }];
        
    } failure:^(ZNGError *error) {
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteServiceChannel"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testCreateAndDeleteServiceChannel"];
}

#pragma mark - PUT methods

- (void)testUpdateServiceChannel
{
    [ZNGServiceChannelClient updateServiceChannelWithId:[self serviceChannelId] withParameters:nil withServiceId:[self serviceId] success:^(ZNGChannel *serviceChannel, ZNGStatus *status) {
                
        XCTAssert(serviceChannel != nil, @"Updated service channel is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateServiceChannel"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateServiceChannel"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testUpdateServiceChannel"];
}

@end
