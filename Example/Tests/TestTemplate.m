//
//  TestTemplate.m
//  ZingleSDK
//
//  Created by Jason Neel on 12/19/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZingleSDK/ZNGTemplate.h"

@interface TestTemplate : XCTestCase

@end

@implementation TestTemplate

- (void) testBodyWithNoReplacement
{
    NSString * body = @"This is a string with no magic replacement";
    ZNGTemplate * template = [[ZNGTemplate alloc] init];
    template.body = body;
    
    XCTAssertEqualObjects([template bodyWithResponseTime:@"5 minutes"], body);
}

- (void) testBodyWithSingleLowercaseReplacement
{
    static NSString * const bodyFormatString = @"We will respond in %@";
    NSString * selectedTime = @"5 minutes";
    NSString * expectedResult = [NSString stringWithFormat:bodyFormatString, selectedTime];
    
    ZNGTemplate * template = [[ZNGTemplate alloc] init];
    template.body = [NSString stringWithFormat:bodyFormatString, @"{response_time}"];
    
    XCTAssertEqualObjects([template bodyWithResponseTime:selectedTime], expectedResult);
}

- (void) testBodyWithMixedCaseReplacement
{
    static NSString * const bodyFormatString = @"We will respond in %@";
    NSString * selectedTime = @"5 minutes";
    NSString * expectedResult = [NSString stringWithFormat:bodyFormatString, selectedTime];
    
    ZNGTemplate * template = [[ZNGTemplate alloc] init];
    template.body = [NSString stringWithFormat:bodyFormatString, @"{rEsPoNsE_tImE}"];
    
    XCTAssertEqualObjects([template bodyWithResponseTime:selectedTime], expectedResult);
}

- (void) testBodyWithMultipleReplacements
{
    static NSString * const bodyFormatString = @"We will respond in %@.  Seriously.  Only %@.  It's hard to believe, I know.";
    NSString * selectedTime = @"15 minutes";
    NSString * expectedResult = [NSString stringWithFormat:bodyFormatString, selectedTime, selectedTime];
    
    ZNGTemplate * template = [[ZNGTemplate alloc] init];
    template.body = [NSString stringWithFormat:bodyFormatString, @"{response_time}", @"{response_time}"];
    
    XCTAssertEqualObjects([template bodyWithResponseTime:selectedTime], expectedResult);
}

@end
