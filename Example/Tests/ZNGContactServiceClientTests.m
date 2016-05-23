//
//  ZNGContactServiceClientTests.m
//  ZingleSDK
//
//  Created by Robert Harrison on 5/23/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGContactServiceClient.h"
#import "ZNGContactService.h"

@interface ZNGContactServiceClientTests : ZNGBaseTests

@end

@implementation ZNGContactServiceClientTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testContactServiceList {
    
    NSDictionary *parameters = @{ @"channel_value" : [self channelValue],
                                  @"channel_type_id" : [self channelType].channelTypeId};
    
    [ZNGContactServiceClient contactServiceListWithParameters:parameters success:^(NSArray *contactServices, ZNGStatus *status) {
        
        XCTAssert(contactServices != nil, @"ContactServices are nil!");
        
        // Get the most recent contact service and verify the properties.
        ZNGContactService *contactService = contactServices.firstObject;
        XCTAssertNotNil(contactService, "contactService is nil!");
        
        XCTAssertNotNil(contactService.contactId, "contactService.contactId is nil!");
        
        XCTAssertNotNil(contactService.accountId, "contactService.accountId is nil!");
        XCTAssertTrue([contactService.accountId isEqualToString:[self account].accountId], @"contactService.accountId mis-match!");
        
        XCTAssertNotNil(contactService.serviceId, "contactService.serviceId is nil!");
        XCTAssertTrue([contactService.serviceId isEqualToString:[self serviceId]], @"contactService.serviceId mis-match!");
        
        XCTAssertNotNil(contactService.unreadMessageCount, "contactService.unreadMessageCount is nil!");
        XCTAssertNotNil(contactService.serviceDisplayName, "contactService.serviceDisplayName is nil!");
        XCTAssertNotNil(contactService.accountDisplayName, "contactService.accountDisplayName is nil!");
        XCTAssertNotNil(contactService.lastMessage, "contactService.lastMessage is nil!");
        
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testContactServiceList"];
        
    } failure:^(ZNGError *error) {
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testContactServiceList"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testContactServiceList"];
    
}


@end
