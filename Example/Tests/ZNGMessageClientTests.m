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
    NSDictionary *parameters = @{ @"sort_field" : @"created_at",
                                  @"sort_direction" : @"desc" };
    
    [ZNGMessageClient messageListWithParameters:parameters withServiceId:[self serviceId] success:^(NSArray *messages, ZNGStatus *status) {
        
        XCTAssert(messages != nil, @"Messages are nil!");
        
        // Get the most recent message.
        ZNGMessage *message = messages.firstObject;
        
        // Verify the triggeredByUser exists and contains all the required properties.
        ZNGUser *triggeredByUser = message.triggeredByUser;
        XCTAssertNotNil(triggeredByUser, "message.triggeredByUser is nil!");
        XCTAssertNotNil(triggeredByUser.userId, "triggeredByUser.userId is nil!");
        XCTAssertNotNil(triggeredByUser.email, "triggeredByUser.email is nil!");
        XCTAssertNotNil(triggeredByUser.firstName, "triggeredByUser.firstName is nil!");
        XCTAssertNotNil(triggeredByUser.lastName, "triggeredByUser.lastName is nil!");
        
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMessageList"];
        
    } failure:^(ZNGError *error) {
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMessageList"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testMessageList"];
}

- (void)testMessageListWithAuthorizationClassContact
{
    ZNGContactService *contactService = [[ZNGContactService alloc] init];
    // Only the contactId is required for this test.
    contactService.contactId = @"3d15b92f-9284-4e30-b119-1147f0465d88";
    
    [[ZingleSDK sharedSDK] checkAuthorizationForContactService:contactService success:^(BOOL isAuthorized) {
        
        NSDictionary *parameters = @{ @"sort_field" : @"created_at",
                                      @"sort_direction" : @"desc" };
        
        [ZNGMessageClient messageListWithParameters:parameters withServiceId:[self serviceId] success:^(NSArray *messages, ZNGStatus *status) {
            
            XCTAssert(messages != nil, @"Messages are nil!");
            XCTAssert(messages.count > 0, @"messages.count is 0!");
            
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testMessageListWithAuthenticationClassContact"];
            
        } failure:^(ZNGError *error) {
            XCTFail(@"fail: \"%@\"", error);
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testMessageListWithAuthenticationClassContact"];
        }];
        
        
    } failure:^(ZNGError *error) {
        NSLog(@"error: %@", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMessageListWithAuthenticationClassContact"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testMessageListWithAuthenticationClassContact"];
    
}

- (void)testMessageById
{
    [ZNGMessageClient messageWithId:[self messageId] withServiceId:[self serviceId] success:^(ZNGMessage *message, ZNGStatus *status) {
        
        XCTAssert(message != nil, @"Message is nil!");
        
        // Verify the triggeredByUser exists and contains all the required properties.
        ZNGUser *triggeredByUser = message.triggeredByUser;
        XCTAssertNotNil(triggeredByUser, "message.triggeredByUser is nil!");
        XCTAssertNotNil(triggeredByUser.userId, "triggeredByUser.userId is nil!");
        XCTAssertNotNil(triggeredByUser.email, "triggeredByUser.email is nil!");
        XCTAssertNotNil(triggeredByUser.firstName, "triggeredByUser.firstName is nil!");
        XCTAssertNotNil(triggeredByUser.lastName, "triggeredByUser.lastName is nil!");
        
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
    sender.channelValue = @"+18585557777";
    
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
    [ZNGMessageClient markMessageReadWithId:@"bcfc4bc0-69cb-48c6-99cc-0bbac8801ee4" withServiceId:[self serviceId] success:^(ZNGMessage *message, ZNGStatus *status) {
        
        XCTAssert(message != nil, @"Message is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMarkMessageRead"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMarkMessageRead"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testMarkMessageRead"];
}

- (void)testMarkMessageReadWithAuthorizationClassContact
{
    
    ZNGContactService *contactService = [[ZNGContactService alloc] init];
    // Only the contactId is required for this test.
    contactService.contactId = @"3d15b92f-9284-4e30-b119-1147f0465d88";
    
    [[ZingleSDK sharedSDK] checkAuthorizationForContactService:contactService success:^(BOOL isAuthorized) {
        
        [ZNGMessageClient markMessageReadWithId:@"ecc68609-dedb-4b3c-9e05-1477a08864b7" withServiceId:[self serviceId] success:^(ZNGMessage *message, ZNGStatus *status) {
            
            XCTAssert(message != nil, @"Message is nil!");
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testMarkMessageReadWithAuthorizationClassContact"];
            
        } failure:^(ZNGError *error) {
            
            XCTFail(@"fail: \"%@\"", [error description]);
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testMarkMessageReadWithAuthorizationClassContact"];
        }];
        
        
    } failure:^(ZNGError *error) {
        NSLog(@"error: %@", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMarkMessageReadWithAuthorizationClassContact"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testMarkMessageReadWithAuthorizationClassContact"];
    
}

- (void)testMarkMessagesRead
{
    [ZNGMessageClient markAllMessagesReadWithServiceId:[self serviceId] success:^(ZNGStatus *status){
        
        XCTAssert(status != nil, @"Status is nil!");
        XCTAssert(status.statusCode == 200, @"statusCode is not 200!");
        
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMarkMessagesRead"];
        
    } failure:^(ZNGError *error) {
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMarkMessagesRead"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testMarkMessagesRead"];
}

- (void)testMarkMessagesReadWithAuthorizationClassContact
{
    ZNGContactService *contactService = [[ZNGContactService alloc] init];
    // Only the contactId is required for this test.
    contactService.contactId = @"3d15b92f-9284-4e30-b119-1147f0465d88";
    
    [[ZingleSDK sharedSDK] checkAuthorizationForContactService:contactService success:^(BOOL isAuthorized) {
        
        [ZNGMessageClient markAllMessagesReadWithServiceId:[self serviceId] success:^(ZNGStatus *status){
            
            XCTAssert(status != nil, @"Status is nil!");
            XCTAssert(status.statusCode == 200, @"statusCode is not 200!");
            
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testMarkMessagesReadWithAuthorizationClassContact"];
            
        } failure:^(ZNGError *error) {
            XCTFail(@"fail: \"%@\"", [error description]);
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testMarkMessagesReadWithAuthorizationClassContact"];
        }];
        
        
    } failure:^(ZNGError *error) {
        NSLog(@"error: %@", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testMarkMessagesReadWithAuthorizationClassContact"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testMarkMessagesReadWithAuthorizationClassContact"];
    
}

- (void)testDeleteMessages
{
    
    [ZNGMessageClient deleteMessages:@[@"b37a27e6-e815-407b-9313-384b6731ffc7"] withServiceId:[self serviceId] success:^(ZNGStatus *status) {
        
        XCTAssert(status != nil, @"Status is nil!");
        XCTAssert(status.statusCode == 200, @"statusCode is not 200!");
        
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testDeleteMessages"];
        
    } failure:^(ZNGError *error) {
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testDeleteMessages"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testDeleteMessages"];
}

- (void)testDeleteAllMessages
{
    
    [ZNGMessageClient deleteAllMessagesForContactId:[self contactId] withServiceId:[self serviceId] success:^(ZNGStatus *status) {
        
        XCTAssert(status != nil, @"Status is nil!");
        XCTAssert(status.statusCode == 200, @"statusCode is not 200!");
        
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testDeleteAllMessages"];
        
    } failure:^(ZNGError *error) {
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testDeleteAllMessages"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testDeleteAllMessages"];
    
}

@end
