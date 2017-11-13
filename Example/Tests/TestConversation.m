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

- (void) testDeletedDelayedMessageDisappears
{
    ZNGConversationServiceToContact * conversation = [self freshConversation];
    ZNGMockEventClient * eventClient = (ZNGMockEventClient *)conversation.eventClient;
    
    ZNGEvent * event1 = [[ZNGEvent alloc] init];
    event1.eventId = @"1234-123412341234-123412341234-1234";
    event1.body = @"First message";
    ZNGEvent * event2 = [[ZNGEvent alloc] init];
    ZNGMessage * message2 = [[ZNGMessage alloc] init];
    NSString * message2Body = @"A second message";
    message2.isDelayed = YES;
    message2.body = message2Body;
    event2.eventId = @"5678-567856785687-567856785678-5678";
    event2.body = message2Body;
    event2.message = message2;
    event2.eventType = @"message";
    
    NSArray<ZNGEvent *> * bothEvents = @[event1, event2];
    NSArray<ZNGEvent *> * onlyFirstEvent = @[event1];
    eventClient.events = [[bothEvents reverseObjectEnumerator] allObjects];
    
    [self keyValueObservingExpectationForObject:conversation keyPath:NSStringFromSelector(@selector(events)) expectedValue:bothEvents];
    [conversation loadRecentEventsErasingOlderData:YES];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    
    // Remove the delayed message
    eventClient.events = [[onlyFirstEvent reverseObjectEnumerator] allObjects];
    
    [self keyValueObservingExpectationForObject:conversation keyPath:NSStringFromSelector(@selector(events)) expectedValue:onlyFirstEvent];
    [conversation loadRecentEventsErasingOlderData:NO];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void) testDeletedDelayedMessageDisappearsWithSimultaneousNewMessageAppearing
{
    ZNGConversationServiceToContact * conversation = [self freshConversation];
    ZNGMockEventClient * eventClient = (ZNGMockEventClient *)conversation.eventClient;
    
    ZNGEvent * event1 = [[ZNGEvent alloc] init];
    event1.eventId = @"1234-123412341234-123412341234-1234";
    event1.body = @"First message";
    ZNGEvent * event2 = [[ZNGEvent alloc] init];
    ZNGMessage * message2 = [[ZNGMessage alloc] init];
    NSString * message2Body = @"A second message";
    message2.isDelayed = YES;
    message2.body = message2Body;
    event2.eventId = @"5678-567856785687-567856785678-5678";
    event2.body = message2Body;
    event2.message = message2;
    event2.eventType = @"message";
    ZNGEvent * event3 = [[ZNGEvent alloc] init];
    event3.eventId = @"3333-33333333-333333333-3333";
    event3.body = @"A third message";
    
    NSArray<ZNGEvent *> * oneNormalOneDelayed = @[event1, event2];
    NSArray<ZNGEvent *> * oneNormalOneNewMessage = @[event1, event3];
    eventClient.events = [[oneNormalOneDelayed reverseObjectEnumerator] allObjects];
    
    [self keyValueObservingExpectationForObject:conversation keyPath:NSStringFromSelector(@selector(events)) expectedValue:oneNormalOneDelayed];
    [conversation loadRecentEventsErasingOlderData:YES];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    
    // Remove the delayed message
    eventClient.events = [[oneNormalOneNewMessage reverseObjectEnumerator] allObjects];
    
    [self keyValueObservingExpectationForObject:conversation keyPath:NSStringFromSelector(@selector(events)) handler:^BOOL(ZNGConversationServiceToContact * _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return ([observedObject.events isEqualToArray:oneNormalOneNewMessage]);
    }];
    
    [conversation loadRecentEventsErasingOlderData:NO];
    
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Actual value of events array is: %@", conversation.events);
        }
    }];
}

// TODO: Address the following two unit tests that have never passed.

/**
 *  If a sending note ends up appearing somewhere other than as the most recent event, we need to ensure that it moves up in the
 *   event list after sending.  This happens in the wild when an internal note is added to a conversation that has a delayed message
 *   that has not yet been sent.
 */
//- (void) testNoteOrderAfterSending
//{
//    ZNGConversationServiceToContact * conversation = [self freshConversation];
//    ZNGMockEventClient * eventClient = (ZNGMockEventClient *)conversation.eventClient;
//
//    ZNGEvent * event1 = [[ZNGEvent alloc] init];
//    event1.eventId = @"1234-123412341234-123412341234-1234";
//    event1.body = @"First message";
//    ZNGEvent * event2 = [[ZNGEvent alloc] init];
//    ZNGMessage * message2 = [[ZNGMessage alloc] init];
//    NSString * message2Body = @"A second message";
//    message2.isDelayed = YES;
//    message2.body = message2Body;
//    event2.eventId = @"5678-567856785687-567856785678-5678";
//    event2.body = message2Body;
//    event2.message = message2;
//    event2.eventType = @"message";
//
//    ZNGEvent * noteEvent = [[ZNGEvent alloc] init];
//    NSString * noteText = @"This is the note";
//    noteEvent.body = noteText;
//    noteEvent.eventId = @"3242-234234-2342342-2342";
//
//    NSArray<ZNGEvent *> * twoEvents = @[event1, event2];
//    NSArray<ZNGEvent *> * twoEventsWithNoteBetween = @[event1, noteEvent, event2];
//
//    // In reverse since the mock data is oldest first
//    eventClient.events = [[twoEvents reverseObjectEnumerator] allObjects];
//
//    // Load initial data with two events
//    [self keyValueObservingExpectationForObject:conversation keyPath:NSStringFromSelector(@selector(events)) expectedValue:twoEvents];
//    [conversation loadRecentEventsErasingOlderData:YES];
//    [self waitForExpectationsWithTimeout:3.0 handler:nil];
//
//    [self keyValueObservingExpectationForObject:conversation keyPath:NSStringFromSelector(@selector(events)) expectedValue:twoEventsWithNoteBetween];
//
//    eventClient.events = [[twoEventsWithNoteBetween reverseObjectEnumerator] allObjects];
//    [conversation addInternalNote:noteText success:nil failure:^(ZNGError * _Nonnull error) {
//        XCTFail(@"Internal note failure block was called. :(");
//    }];
//
//    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError * _Nullable error) {
//        if (error != nil) {
//            NSLog(@"Actual events array is: %@", conversation.events);
//        }
//    }];
//}

//- (void) testReorderedEvents
//{
//    ZNGConversationServiceToContact * conversation = [self freshConversation];
//    ZNGMockEventClient * eventClient = (ZNGMockEventClient *)conversation.eventClient;
//
//    ZNGEvent * event1 = [[ZNGEvent alloc] init];
//    event1.eventId = @"1234-123412341234-123412341234-1234";
//    event1.body = @"First message";
//    ZNGEvent * event2 = [[ZNGEvent alloc] init];
//    event2.eventId = @"5678-567856785687-567856785678-5678";
//    event2.body = @"A second message";
//    ZNGEvent * event3 = [[ZNGEvent alloc] init];
//    event3.eventId = @"9234-28435973423-2342394871234-2342";
//    event3.body = @"Another magic event";
//
//    NSArray<ZNGEvent *> * originalOrder = @[event2, event1];
//    NSArray<ZNGEvent *> * reversed = [[originalOrder reverseObjectEnumerator] allObjects];
//    NSArray<ZNGEvent *> * originalOrderPlusOne = @[event3, event2, event1];
//    NSArray<ZNGEvent *> * reversedPlusOne = [[originalOrderPlusOne reverseObjectEnumerator] allObjects];
//
//    eventClient.events = originalOrder;
//
//    // Note that the original order is reversed because of the way event data is ordered in normal pagination and the way it is
//    //  contained in a ZNGConversation.  Event data from the API is newest first; data in ZNGConversation is oldest first with subsequent
//    //  pages of data shoved to the head.
//    [self keyValueObservingExpectationForObject:conversation keyPath:NSStringFromSelector(@selector(events)) expectedValue:reversed];
//    [conversation loadRecentEventsErasingOlderData:YES];
//
//    [self waitForExpectationsWithTimeout:3.0 handler:nil];
//
//
//    // Reverse data, adding one more event to trigger a refresh
//    eventClient.events = reversedPlusOne;
//    [self keyValueObservingExpectationForObject:conversation keyPath:NSStringFromSelector(@selector(events)) expectedValue:originalOrderPlusOne];
//    [conversation loadRecentEventsErasingOlderData:NO];
//
//    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError * _Nullable error) {
//        if (error != nil) {
//            if ([conversation.events isEqual:originalOrderPlusOne]) {
//                NSLog(@"Logic no longer applies");
//            } else {
//                NSLog(@"Events are: %@\n instead of expected: %@", conversation.events, originalOrderPlusOne);
//            }
//        }
//    }];
//}

@end
