//
//  TestContacts.m
//  ZingleSDK
//
//  Created by Jason Neel on 7/12/17.
//  Copyright © 2017 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZingleSDK/ZNGContact.h"
#import "ZingleSDK/ZNGContactGroup.h"

@interface TestContacts : XCTestCase

@end

@implementation TestContacts

- (ZNGContact *)aDude
{
    ZNGContact * dude = [[ZNGContact alloc] init];
    dude.contactId = @"ABCDEF-123456789-987654321-FEDCBA";
    dude.isConfirmed = YES;
    dude.updatedAt = [NSDate date];
    
    ZNGContactFieldValue * firstName = [[ZNGContactFieldValue alloc] init];
    ZNGContactField * firstNameField = [[ZNGContactField alloc] init];
    firstNameField.displayName = @"First Name";
    firstName.customField = firstNameField;
    firstName.value = @"Contact";
    
    ZNGContactFieldValue * lastName = [[ZNGContactFieldValue alloc] init];
    ZNGContactField * lastNameField = [[ZNGContactField alloc] init];
    lastNameField.displayName = @"Last Name";
    lastName.customField = lastNameField;
    lastName.value = @"McContacterson";

    dude.customFieldValues = @[[firstName copy], lastName];
    
    return dude;
}

- (void) testContactCopying
{
    ZNGContact * dude = [self aDude];
    
    ZNGContact * copiedDude = [dude copy];
    
    XCTAssertFalse(dude == copiedDude, @"Copied ZNGContact should actually be copied instead of just being referenced again.");
    XCTAssertFalse([copiedDude changedSince:dude], @"Copied ZNGContact should not return YES for changedSince:original");
}

// There was a crash bug in July 2017 if a ZNGContact was copied that belonged to a contact group
//  with null for either textColor or backgroundColor.
- (void) testCopyDudeWithColorlessGroup
{
    ZNGContact * dude = [self aDude];
    
    ZNGContactGroup * colorlessGroup = [[ZNGContactGroup alloc] init];
    colorlessGroup.displayName = @"Colorless Group";
    colorlessGroup.groupId = @"1234-123412341234-123412341234-12341";
    dude.groups = @[colorlessGroup];
    
    ZNGContact * copiedDude = [dude copy];
    
    XCTAssertFalse(dude == copiedDude, @"Copied ZNGContact should actually be copied instead of just being referenced again.");
    XCTAssertFalse([copiedDude changedSince:dude], @"Copied ZNGContact should not return YES for changedSince:original");
}

@end
