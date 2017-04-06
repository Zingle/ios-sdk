//
//  TestMessageSending.m
//  ZingleSDK
//
//  Created by Jason Neel on 4/6/17.
//  Copyright © 2017 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ZingleSDK/ZingleAccountSession.h>
#import <ZingleSDK/ZNGConversationServiceToContact.h>
#import <ZingleSDK/ZNGSocketClient.h>
#import "ZNGMockMessageClient.h"
#import "ZNGMockContactClient.h"
#import "ZNGMockServiceClient.h"
#import "ZNGStubbedEventClient.h"

@interface TestMessageSending : XCTestCase

@end

@implementation TestMessageSending
{
    ZNGMockMessageClient * messageClient;
    ZNGConversationServiceToContact * conversation;
}

- (void)setUp {
    [super setUp];
    
    ZingleAccountSession * session = [ZingleSDK accountSessionWithToken:@"token" key:@"key"];
    ZNGSocketClient * socketClient = [[ZNGSocketClient alloc] initWithSession:session];
    
    ZNGChannel * channel = [[ZNGChannel alloc] init];
    ZNGChannelType * channelType = [[ZNGChannelType alloc] init];
    channelType.channelTypeId = @"1111-22222222222-333333333333-4444";
    channel.channelType = channelType;
    
    messageClient = [[ZNGMockMessageClient alloc] init];
    
    ZNGService * service = [[ZNGService alloc] init];
    ZNGContact * contact = [[ZNGContact alloc] init];
    contact.contactId = @"1234-ABCDEFABCDEFABCD-EFABCDEFABCD-1234";
    ZNGStubbedEventClient * eventClient = [[ZNGStubbedEventClient alloc] init];
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    
    conversation = [[ZNGConversationServiceToContact alloc] initFromService:service toContact:contact withCurrentUserId:@"" usingChannel:channel withMessageClient:messageClient eventClient:eventClient contactClient:contactClient socketClient:socketClient];
}

- (void) testCompletionBlockCalled
{
    XCTestExpectation * expectation = [self expectationWithDescription:@"Completion block called after sending message"];
    
    [conversation sendMessageWithBody:@"body" imageData:nil uuid:nil success:^(ZNGStatus * _Nullable status) {
        [expectation fulfill];
    } failure:^(ZNGError * _Nullable error) {
        XCTFail(@"Failure block was called when test should trigger success");
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void) testFailureBlockCalled
{
    XCTestExpectation * expectation = [self expectationWithDescription:@"Completion block called after sending message"];
    
    messageClient.alwaysFail = YES;
    
    [conversation sendMessageWithBody:@"body" imageData:nil uuid:nil success:^(ZNGStatus * _Nullable status) {
        XCTFail(@"Success block was called when test should trigger failure");
    } failure:^(ZNGError * _Nullable error) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    messageClient.alwaysFail = NO;
}

@end
