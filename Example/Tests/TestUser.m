//
//  TestUser.m
//  ZingleSDK
//
//  Created by Jason Neel on 9/25/17.
//  Copyright © 2017 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZingleSDK/ZNGUser.h"

static NSString * const FirstNameKey = @"first_name";
static NSString * const LastNameKey = @"last_name";
static NSString * const EmailKey = @"username";
static NSString * const AvatarKey = @"avatar_asset";

@interface TestUser : XCTestCase

@end

@implementation TestUser

- (NSDictionary *) socketDataDictionaryWithFirstName:(id)first lastName:(id)last email:(id)email avatarPath:(id)avatar
{
    NSMutableDictionary * data = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    data[FirstNameKey] = first;
    data[LastNameKey] = last;
    data[EmailKey] = email;
    data[AvatarKey] = avatar;
    
    return data;
}

- (void) testFullNameFromSocketData
{
    NSString * first = @"Dudey";
    NSString * last = @"McDuderson";
    NSString * email = @"doesntmatter@nothing.com";
    NSString * expectedName = [NSString stringWithFormat:@"%@ %@", first, last];
    
    NSDictionary * data = [self socketDataDictionaryWithFirstName:first lastName:last email:email avatarPath:nil];
    ZNGUser * dude = [ZNGUser userFromSocketData:data];
    
    NSString * name = [dude fullName];
    
    XCTAssertEqualObjects(name, expectedName, @"Full name should be %@ but was %@", expectedName, name);
}

- (void) testOnlyEmailAddressAsDisplayName
{
    NSString * email = @"dude@duders.com";
    NSDictionary * data = [self socketDataDictionaryWithFirstName:nil lastName:nil email:email avatarPath:nil];
    ZNGUser * dude = [ZNGUser userFromSocketData:data];
    
    XCTAssertEqualObjects([dude fullName], email, @"A user with no first/last names but with an email address should use the email address as a display name.");
}

- (void) testNullNameData
{
    NSString * first = @"Dudey";
    id nullName = [NSNull null];
    NSString * expectedName = first;
    
    NSDictionary * data = [self socketDataDictionaryWithFirstName:first lastName:nullName email:nil avatarPath:nil];
    ZNGUser * dude = [ZNGUser userFromSocketData:data];
    
    NSString * name = [dude fullName];
    
    XCTAssertEqualObjects(name, expectedName, @"Full name with only first name data should be the first name");
}

@end
