//
//  TestContactSession.m
//  ZingleSDK
//
//  Created by Jason Neel on 10/26/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZingleSDK/ZingleAccountSession.h"

@interface TestContactSession : XCTestCase

@end

@implementation TestContactSession

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testSuccessfulSingleContactSession
{
    ZingleAccountSession * session = [[ZingleAccountSession alloc] initWithToken:@"token" key:@"key" accountChooser:nil serviceChooser:nil errorHandler:nil];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    
    
}

@end
