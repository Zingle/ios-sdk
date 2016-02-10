//
//  ZNGContactChannelClientTests.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/9/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGContactChannelClient.h"
#import "ZNGAvailablePhoneNumberClient.h"

@interface ZNGContactChannelClientTests : ZNGBaseTests

@end

@implementation ZNGContactChannelClientTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - GET methods

- (void)testContactChannelById
{
    [ZNGContactChannelClient contactChannelWithId:[self contactChannelId] withContactId:[self contactId] withServiceId:[self serviceId] success:^(ZNGContactChannel *contactChannel) {
        
        XCTAssert(contactChannel != nil, @"Contact channel is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testContactChannelById"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testContactChannelById"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testContactChannelById"];
}

#pragma mark - POST and DELETE methods

- (void)testCreateAndDeleteContactChannel
{
    [ZNGAvailablePhoneNumberClient availablePhoneNumberListForCountry:@"US" success:^(NSArray *availableNumbers) {
        
        ZNGAvailablePhoneNumber *number = [availableNumbers lastObject];
        
        [ZNGContactChannelClient saveContactChannel:[self contactChannelWithValue:number.phoneNumber] withContactId:[self contactId] withServiceId:[self serviceId] success:^(ZNGContactChannel *contactChannel) {
            
            XCTAssert(contactChannel != nil, @"Created contact channel is nil!");
            
            [ZNGContactChannelClient deleteContactChannelWithId:contactChannel.contactChannelId withContactId:[self contactId] withServiceId:[self serviceId] success:^(ZNGContactChannel *contactChannel) {
                
                XCTAssert(contactChannel != nil, @"Deleted contact channel is nil!");
                [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteContactChannel"];
                
            } failure:^(ZNGError *error) {
                
                XCTFail(@"fail: \"%@\"", [error description]);
                [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteContactChannel"];
            }];
            
        } failure:^(ZNGError *error) {
            
            XCTFail(@"fail: \"%@\"", [error description]);
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteContactChannel"];
        }];
        
    } failure:^(ZNGError *error) {
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testCreateAndDeleteContactChannel"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testCreateAndDeleteContactChannel"];
}

#pragma mark - PUT methods

- (void)testUpdateContactChannel
{
    NSDictionary *updateParams = @{
                                   @"display_name" : @"BUSINESS"
                                   };
    [ZNGContactChannelClient updateContactChannelWithId:[self contactChannelId] withParameters:updateParams withContactId:[self contactId] withServiceId:[self serviceId] success:^(ZNGContactChannel *contactChannel) {
        
        XCTAssert(contactChannel != nil, @"Updated contact channel is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateContactChannel"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateContactChannel"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testUpdateContactChannel"];
}

@end
