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
#import <ZingleSDK/ZNGEvent.h>
#import "ZNGMockMessageClient.h"
#import "ZNGMockContactClient.h"
#import "ZNGMockServiceClient.h"
#import "ZNGMockEventClient.h"

@interface TestConversation : XCTestCase

@end

@implementation TestConversation

- (ZNGConversationServiceToContact *) freshConversation
{
    ZingleAccountSession * session = [ZingleSDK accountSessionWithToken:@"token" key:@"key"];
    ZNGSocketClient * socketClient = [[ZNGSocketClient alloc] initWithSession:session];
    
    ZNGChannel * channel = [[ZNGChannel alloc] init];
    ZNGChannelType * channelType = [[ZNGChannelType alloc] init];
    channelType.channelTypeId = @"1111-22222222222-333333333333-4444";
    channel.channelType = channelType;
    
    ZNGMockMessageClient * messageClient = [[ZNGMockMessageClient alloc] init];
    
    ZNGService * service = [[ZNGService alloc] init];
    ZNGContact * contact = [[ZNGContact alloc] init];
    contact.contactId = @"1234-ABCDEFABCDEFABCD-EFABCDEFABCD-1234";
    ZNGMockEventClient * eventClient = [[ZNGMockEventClient alloc] init];
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    
    return [[ZNGConversationServiceToContact alloc] initFromService:service toContact:contact withCurrentUserId:@"" usingChannel:channel withMessageClient:messageClient eventClient:eventClient contactClient:contactClient socketClient:socketClient];
}

- (void) testCompletionBlockCalled
{
    ZNGConversationServiceToContact * conversation = [self freshConversation];
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
    ZNGConversationServiceToContact * conversation = [self freshConversation];
    ZNGMockMessageClient * messageClient = (ZNGMockMessageClient *)conversation.messageClient;
    XCTestExpectation * expectation = [self expectationWithDescription:@"Completion block called after sending message"];
    
    messageClient.alwaysFail = YES;
    
    [conversation sendMessageWithBody:@"body" imageData:nil uuid:nil success:^(ZNGStatus * _Nullable status) {
        XCTFail(@"Success block was called when test should trigger failure");
    } failure:^(ZNGError * _Nullable error) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void) testPendingEventImmediatelyPresent
{
    NSString * body = @"body of in progress message";
    ZNGConversationServiceToContact * conversation = [self freshConversation];
    
    [self keyValueObservingExpectationForObject:conversation keyPath:NSStringFromSelector(@selector(events)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        for (ZNGEvent * event in conversation.events) {
            if (([event.message.body isEqualToString:body]) && (event.sending)) {
                return YES;
            }
        }
        
        return NO;
    }];
    
    [conversation sendMessageWithBody:body imageData:nil uuid:nil success:nil failure:^(ZNGError * _Nullable error) {
        XCTFail(@"Failure block was called when test should trigger success");
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

@end
