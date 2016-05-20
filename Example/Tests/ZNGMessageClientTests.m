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
#import "ZNGParticipant.h"

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
    [ZNGMessageClient messageListWithParameters:nil withServiceId:[self serviceId] success:^(NSArray *messages, ZNGStatus *status) {
        
        XCTAssert(messages != nil, @"Messages are nil!");
        
        // Verify the triggeredByUser exists and contains all the User properties.
        for (ZNGMessage *message in messages) {
            
            ZNGUser *triggeredByUser = message.triggeredByUser;
            
            XCTAssertNotNil(triggeredByUser, "message.triggeredByUser is nil!");
            
            XCTAssertNotNil(triggeredByUser.userId, "triggeredByUser.userId is nil!");
            XCTAssertNotNil(triggeredByUser.email, "triggeredByUser.email is nil!");
            XCTAssertNotNil(triggeredByUser.firstName, "triggeredByUser.firstName is nil!");
            XCTAssertNotNil(triggeredByUser.lastName, "triggeredByUser.lastName is nil!");
            XCTAssertNotNil(triggeredByUser.title, "triggeredByUser.title is nil!");
            
        }
        
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMessageList"];
        
    } failure:^(ZNGError *error) {
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMessageList"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testMessageList"];
}

- (void)testMessageById
{
    [ZNGMessageClient messageWithId:[self messageId] withServiceId:[self serviceId] success:^(ZNGMessage *message, ZNGStatus *status) {
        
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
    ZNGParticipant *sender = [[ZNGParticipant alloc] init];
    sender.participantId = [self serviceId];
    sender.channelValue = @"+16194323023";
    
    ZNGParticipant *recipient = [[ZNGParticipant alloc] init];
    recipient.channelValue = @"+12242171591";
    
    ZNGNewMessage *newMessage = [[ZNGNewMessage alloc] init];
    newMessage.senderType = @"service";
    newMessage.sender = sender;
    newMessage.recipientType = @"contact";
    newMessage.recipients = @[recipient];
    newMessage.channelTypeIds = @[@"0a293ea3-4721-433e-a031-610ebcf43255"];
    newMessage.body = @"iOS Testing again";
    
    [ZNGMessageClient sendMessage:newMessage withServiceId:[self serviceId] success:^(ZNGMessage *message, ZNGStatus *status) {
        
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
    [ZNGMessageClient markMessageReadWithId:@"bb707200-7137-42f2-8933-a0b96270d5cc" withServiceId:[self serviceId] success:^(ZNGMessage *message, ZNGStatus *status) {
        
        XCTAssert(message != nil, @"Message is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMarkMessageRead"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMarkMessageRead"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testMarkMessageRead"];
}

@end
