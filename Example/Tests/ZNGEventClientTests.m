//
//  ZNGEventClientTests.m
//  ZingleSDK
//
//  Created by Robert Harrison on 5/20/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGEventClient.h"

@interface ZNGEventClientTests : ZNGBaseTests

@end

@implementation ZNGEventClientTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - GET methods

- (void)testEventList
{
    NSDictionary *parameters = @{ @"sort_field" : @"created_at",
                                  @"sort_direction" : @"desc" };
    
    [ZNGEventClient eventListWithParameters:parameters withServiceId:[self serviceId] success:^(NSArray *events, ZNGStatus *status) {
        
        XCTAssert(events != nil, @"Events are nil!");
        
        // Get the most recent event.
        ZNGEvent *event = events.firstObject;
        
        // Verify the triggeredByUser exists and contains all the required properties.
        ZNGUser *triggeredByUser = event.triggeredByUser;
        XCTAssertNotNil(triggeredByUser, "event.triggeredByUser is nil!");
        XCTAssertNotNil(triggeredByUser.userId, "triggeredByUser.userId is nil!");
        XCTAssertNotNil(triggeredByUser.email, "triggeredByUser.email is nil!");
        XCTAssertNotNil(triggeredByUser.firstName, "triggeredByUser.firstName is nil!");
        XCTAssertNotNil(triggeredByUser.lastName, "triggeredByUser.lastName is nil!");
    
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testEventList"];
        
    } failure:^(ZNGError *error) {
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testEventList"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testEventList"];
}

- (void)testEventById
{
    [ZNGEventClient eventWithId:[self eventId] withServiceId:[self serviceId] success:^(ZNGEvent *event, ZNGStatus *status) {
        
        XCTAssert(event != nil, @"Event is nil!");
        
        // Verify the triggeredByUser exists and contains all the required User properties.
        ZNGUser *triggeredByUser = event.triggeredByUser;
        XCTAssertNotNil(triggeredByUser, "event.triggeredByUser is nil!");
        XCTAssertNotNil(triggeredByUser.userId, "triggeredByUser.userId is nil!");
        XCTAssertNotNil(triggeredByUser.email, "triggeredByUser.email is nil!");
        XCTAssertNotNil(triggeredByUser.firstName, "triggeredByUser.firstName is nil!");
        XCTAssertNotNil(triggeredByUser.lastName, "triggeredByUser.lastName is nil!");
        
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testEventById"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testEventById"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testEventById"];
}

#pragma mark - POST methods

- (void)testSendEvent
{
    ZNGNewEvent *newEvent = [[ZNGNewEvent alloc] init];
    newEvent.eventType = @"note";
    newEvent.contactId = @"c456a92f-cd38-48aa-a78d-c24235a79a64";
    newEvent.body = @"iOS Testing";
    
    [ZNGEventClient sendEvent:newEvent withServiceId:[self serviceId] success:^(ZNGEvent *event, ZNGStatus *status) {
        
        XCTAssert(event != nil, @"Created event is nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testSendEvent"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", [error description]);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testSendEvent"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testSendEvent"];
}

@end
