//
//  ZNGMessageClientTests.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/9/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGMessageClient.h"
#import "ZNGRecipient.h"
#import "ZNGSender.h"

@interface ZNGMessageClientTests : ZNGBaseTests

@end

@implementation ZNGMessageClientTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - GET methods

- (void)testMessageList
{
    [ZNGMessageClient messageListWithParameters:nil withServiceId:[self serviceId] success:^(NSArray *messages) {
        
        XCTAssert(messages != nil, @"Messages are nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMessageList"];
        
    } failure:^(ZNGError *error) {
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMessageList"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testMessageList"];
}

- (void)testMessageById
{
    [ZNGMessageClient messageWithId:[self messageId] withServiceId:[self serviceId] success:^(ZNGMessage *message) {
        
        XCTAssert(message != nil, @"Message is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMessageById"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMessageById"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testMessageById"];
}

#pragma mark - POST methods

- (void)testSendMessage
{
    ZNGSender *sender = [[ZNGSender alloc] init];
    sender.senderId = @"e545a46e-bfcd-4db2-bfee-8e590fdcb33f";
    sender.channelValue = @"+18582810205";
    
    ZNGRecipient *recipient = [[ZNGRecipient alloc] init];
    recipient.channelValue = @"+12242171591";
    
    ZNGNewMessage *newMessage = [[ZNGNewMessage alloc] init];
    newMessage.senderType = @"service";
    newMessage.sender = sender;
    newMessage.recipientType = @"contact";
    newMessage.recipients = @[recipient];
    newMessage.channelTypeIds = @[@"0a293ea3-4721-433e-a031-610ebcf43255"];
    newMessage.body = @"iOS Testing again";
    
    [ZNGMessageClient sendMessage:newMessage withServiceId:[self serviceId] success:^(ZNGMessage *message) {
        
        XCTAssert(message != nil, @"Created message is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testSendMessage"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testSendMessage"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testSendMessage"];
}

- (void)testMarkMessageRead
{
    [ZNGMessageClient markMessageReadWithId:@"d4d22b55-f828-4cd9-bba9-def32a78b04d" withChannelId:@"af7c17e4-ee9d-479b-bf3b-91e865d31339" withServiceId:[self serviceId] success:^(ZNGMessage *message) {
        
        XCTAssert(message != nil, @"Message is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMarkMessageRead"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMarkMessageRead"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testMarkMessageRead"];
}

@end
