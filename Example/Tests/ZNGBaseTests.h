//
//  ZNGBaseTests.h
//  ZingleSDK
//
//  Created by Ryan Farley on 2/5/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGAsyncSemaphor.h"
#import "ZNGService.h"
#import "ZNGChannel.h"
#import "ZNGContact.h"
#import "ZNGNewChannel.h"

@interface ZNGBaseTests : XCTestCase

- (NSString *)accountId;
- (NSString *)planId;
- (NSString *)serviceId;
- (NSString *)timeZone;
- (NSString *)planCode;
- (ZNGServiceAddress *)serviceAddress;
- (ZNGService *)service;
- (ZNGAccount *)account;
- (NSString *)serviceChannelId;
- (ZNGChannel *)serviceChannelWithValue:(NSString *)value;
- (ZNGNewChannel *)contactChannelWithValue:(NSString *)value;
- (ZNGContact *)contact;
- (NSString *)automationId;
- (NSString *)labelId;
- (NSString *)contactId;
- (NSString *)contactChannelId;
- (NSString *)messageId;

@end
