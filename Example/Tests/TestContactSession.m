//
//  TestContactSession.m
//  ZingleSDK
//
//  Created by Jason Neel on 10/26/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZingleSDK/ZingleContactSession.h"
#import "ZNGMockAccountClient.h"
#import "ZNGMockContactClient.h"
#import "ZNGMockServiceClient.h"
#import "ZNGMockContactServiceClient.h"
#import "ZNGMockUserAuthorizationClient.h"

@interface TestContactSession : XCTestCase

@end

@implementation TestContactSession
{
    ZNGAccount * account1;
    ZNGAccount * account2;
    ZNGService * account1service1;
    ZNGService * account2service1;
    ZNGService * account2service2;
    ZNGContactService * contactService1;
    ZNGContactService * contactService2;
    
    ZNGContact * me;
}

- (void)setUp
{
    [super setUp];
    
    // File names of the test data in our bundle
    NSString * account1FileName = @"devTestAccount";
    NSString * account2FileName = @"luisTestAccount";
    NSString * service1FileName = @"devEnterpriseService";
    NSString * service2FileName = @"luisTestService";
    NSString * service3FileName = @"luisIOSTest";
    NSString * contactService1FileName = @"devEnterpriseService-contactService";
    NSString * contactService2FileName = @"luisTestService-contactService";
    
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    
    NSString * path = [bundle pathForResource:service1FileName ofType:@"json"];
    NSData * json = [NSData dataWithContentsOfFile:path];
    NSDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    account1service1 = [MTLJSONAdapter modelOfClass:[ZNGService class] fromJSONDictionary:dictionary error:nil];
    XCTAssertNotNil(account1service1, @"Unable to load test service data");
    
    path = [bundle pathForResource:service2FileName ofType:@"json"];
    json = [NSData dataWithContentsOfFile:path];
    dictionary = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    account2service1 = [MTLJSONAdapter modelOfClass:[ZNGService class] fromJSONDictionary:dictionary error:nil];
    XCTAssertNotNil(account2service1, @"Unable to load test service data");
    
    path = [bundle pathForResource:service3FileName ofType:@"json"];
    json = [NSData dataWithContentsOfFile:path];
    dictionary = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    account2service2 = [MTLJSONAdapter modelOfClass:[ZNGService class] fromJSONDictionary:dictionary error:nil];
    XCTAssertNotNil(account2service2, @"Unable to load test service data");
    
    path = [bundle pathForResource:account1FileName ofType:@"json"];
    json = [NSData dataWithContentsOfFile:path];
    dictionary = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    account1 = [MTLJSONAdapter modelOfClass:[ZNGAccount class] fromJSONDictionary:dictionary error:nil];
    XCTAssertNotNil(account1, @"Unable to load test account data");
    
    path = [bundle pathForResource:account2FileName ofType:@"json"];
    json = [NSData dataWithContentsOfFile:path];
    dictionary = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    account2 = [MTLJSONAdapter modelOfClass:[ZNGAccount class] fromJSONDictionary:dictionary error:nil];
    XCTAssertNotNil(account2, @"Unable to load test account data");
    
    path = [bundle pathForResource:contactService1FileName ofType:@"json"];
    json = [NSData dataWithContentsOfFile:path];
    dictionary = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    contactService1 = [MTLJSONAdapter modelOfClass:[ZNGContactService class] fromJSONDictionary:dictionary error:nil];
    XCTAssertNotNil(contactService1, @"Unable to load test contact service data");
    
    path = [bundle pathForResource:contactService2FileName ofType:@"json"];
    json = [NSData dataWithContentsOfFile:path];
    dictionary = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    contactService2 = [MTLJSONAdapter modelOfClass:[ZNGContactService class] fromJSONDictionary:dictionary error:nil];
    XCTAssertNotNil(contactService2, @"Unable to load test contact service data");
    
    
    me = [[ZNGContact alloc] init];
    
    ZNGContactFieldValue * firstName = [[ZNGContactFieldValue alloc] init];
    ZNGContactField * firstNameField = [[ZNGContactField alloc] init];
    firstNameField.displayName = @"First Name";
    firstName.value = @"Me";
    
    ZNGContactFieldValue * lastName = [[ZNGContactFieldValue alloc] init];
    ZNGContactField * lastNameField = [[ZNGContactField alloc] init];
    lastNameField.displayName = @"Last Name";
    lastName.value = @"McMoi";
    
    me.customFieldValues = @[firstName, lastName];
    me.contactId = @"00000000-0000-0000-0000-1234abcd1234";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testSimpleSDKConvenienceInitializer
{
    ZingleContactSession * session = [ZingleSDK contactSessionWithToken:@"token" key:@"key" channelTypeId:@"channelType" channelValue:@"value"];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockUserAuthorizationClient * authClient = [[ZNGMockUserAuthorizationClient alloc] initWithSession:session];
    authClient.contact = me;
    session.userAuthorizationClient = authClient;
    
    ZNGMockAccountClient * accountClient = [[ZNGMockAccountClient alloc] initWithSession:session];
    accountClient.accounts = @[account1];
    session.accountClient = accountClient;
    
    ZNGMockContactServiceClient * contactServiceClient = [[ZNGMockContactServiceClient alloc] initWithSession:session];
    contactServiceClient.contactServices = @[contactService1];
    session.contactServiceClient = contactServiceClient;
    
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(availableContactServices)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        if ([session.availableContactServices count] > 0) {
            ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] initWithSession:session serviceId:contactService1.serviceId];
            contactClient.contact = me;
            
            session.contactClient = contactClient;
            session.contactService = contactService1;
            
            return YES;
        }
        
        return NO;
    }];
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(available)) expectedValue:@(YES)];
    
    [session connect];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testSDKConvenienceInitializerSetsBlocks
{
    ZingleContactSession * session = [ZingleSDK contactSessionWithToken:@"token" key:@"key" channelTypeId:@"channelType" channelValue:@"value" contactServiceChooser:^ZNGContactService * _Nullable(NSArray<ZNGContactService *> * _Nonnull availableContactServices) {
        return nil;
    } errorHandler:^(ZNGError * _Nonnull error) {
        return;
    }];
    
    XCTAssertNotNil(session.contactServiceChooser);
    XCTAssertNotNil(session.errorHandler);
}

- (void) testSuccessfulSingleContactSession
{
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"aValue" contactServiceChooser:nil errorHandler:nil];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockUserAuthorizationClient * authClient = [[ZNGMockUserAuthorizationClient alloc] initWithSession:session];
    authClient.contact = me;
    session.userAuthorizationClient = authClient;
    
    ZNGMockAccountClient * accountClient = [[ZNGMockAccountClient alloc] initWithSession:session];
    accountClient.accounts = @[account1];
    session.accountClient = accountClient;
    
    ZNGMockContactServiceClient * contactServiceClient = [[ZNGMockContactServiceClient alloc] initWithSession:session];
    contactServiceClient.contactServices = @[contactService1];
    session.contactServiceClient = contactServiceClient;
    
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(availableContactServices)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return [session.availableContactServices isEqualToArray:@[contactService1]];
    }];
    
    [session connect];
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        
        [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(available)) expectedValue:@(YES)];
        
        ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] initWithSession:session serviceId:contactService1.serviceId];
        contactClient.contact = me;
        
        session.contactClient = contactClient;
        session.contactService = contactService1;
        
        [self waitForExpectationsWithTimeout:2.0 handler:nil];
    }];
}

- (void) testMultipleContactSessions
{
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"aValue" contactServiceChooser:nil errorHandler:nil];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockUserAuthorizationClient * authClient = [[ZNGMockUserAuthorizationClient alloc] initWithSession:session];
    authClient.contact = me;
    session.userAuthorizationClient = authClient;
    
    ZNGMockAccountClient * accountClient = [[ZNGMockAccountClient alloc] initWithSession:session];
    accountClient.accounts = @[account1];
    session.accountClient = accountClient;
    
    ZNGMockContactServiceClient * contactServiceClient = [[ZNGMockContactServiceClient alloc] initWithSession:session];
    NSArray<ZNGContactService *> * contactServices = @[contactService1, contactService2];
    contactServiceClient.contactServices = contactServices;
    session.contactServiceClient = contactServiceClient;
    
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(availableContactServices)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return [session.availableContactServices isEqualToArray:contactServices];
    }];
    
    [session connect];
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        
        [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(available)) expectedValue:@(YES)];
        
        ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] initWithSession:session serviceId:contactService1.serviceId];
        contactClient.contact = me;
        
        session.contactClient = contactClient;
        session.contactService = contactService1;
        
        [self waitForExpectationsWithTimeout:2.0 handler:nil];
    }];
}

- (void) testContactServiceChoosingBlock
{
    XCTestExpectation * contactServiceChooserExpectation = [self expectationWithDescription:@"Contact chooser block is called"];
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"aValue" contactServiceChooser:^ZNGContactService * _Nullable(NSArray<ZNGContactService *> * _Nonnull availableContactServices) {
        [contactServiceChooserExpectation fulfill];
        return contactService1;
    } errorHandler:nil];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockUserAuthorizationClient * authClient = [[ZNGMockUserAuthorizationClient alloc] initWithSession:session];
    authClient.contact = me;
    session.userAuthorizationClient = authClient;
    
    ZNGMockAccountClient * accountClient = [[ZNGMockAccountClient alloc] initWithSession:session];
    accountClient.accounts = @[account1];
    session.accountClient = accountClient;
    
    ZNGMockContactServiceClient * contactServiceClient = [[ZNGMockContactServiceClient alloc] initWithSession:session];
    NSArray<ZNGContactService *> * contactServices = @[contactService1, contactService2];
    contactServiceClient.contactServices = contactServices;
    session.contactServiceClient = contactServiceClient;
    
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(availableContactServices)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return ([session.availableContactServices count] > 0);
    }];
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(contactService)) expectedValue:contactService1];
    
    [session connect];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testErrorHandlingBlock
{
    XCTestExpectation * errorBlockCalledExpectation = [self expectationWithDescription:@"Error handling block is called"];
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"avalue" contactServiceChooser:nil errorHandler:^(ZNGError * _Nonnull error) {
        [errorBlockCalledExpectation fulfill];
    }];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockContactServiceClient * contactServiceClient = [[ZNGMockContactServiceClient alloc] initWithSession:session];
    NSArray<ZNGContactService *> * contactServices = @[contactService1, contactService2];
    contactServiceClient.error = [ZNGError errorWithDomain:kZingleErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : @"Test error" }];
    contactServiceClient.contactServices = contactServices;
    session.contactServiceClient = contactServiceClient;

    [session connect];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/**
 *  Ensure that a contact object exists and has at least first and last name fields
 */
- (void) testContactWellFormed
{
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"aValue" contactServiceChooser:nil errorHandler:nil];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockUserAuthorizationClient * authClient = [[ZNGMockUserAuthorizationClient alloc] initWithSession:session];
    authClient.contact = me;
    session.userAuthorizationClient = authClient;
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1];
    session.serviceClient = serviceClient;
    
    ZNGMockAccountClient * accountClient = [[ZNGMockAccountClient alloc] initWithSession:session];
    accountClient.accounts = @[account1];
    session.accountClient = accountClient;
    
    ZNGMockContactServiceClient * contactServiceClient = [[ZNGMockContactServiceClient alloc] initWithSession:session];
    contactServiceClient.contactServices = @[contactService1];
    session.contactServiceClient = contactServiceClient;
    
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(availableContactServices)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        if ([session.availableContactServices count] > 0) {
            session.contactService = contactService1;
            return YES;
        }
        
        return NO;
    }];
    
    [session connect];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(available)) expectedValue:@(YES)];

    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] initWithSession:session serviceId:contactService1.serviceId];
    
    // Remove first name and last name fields to ensure the contact session is enforcing their existence
    ZNGContact * contact = [me copy];
    contact.customFieldValues = @[];
    contactClient.contact = contact;
    
    session.contactClient = contactClient;
    session.contactService = contactService1;
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    XCTAssertNotNil([session.contact firstNameFieldValue]);
    XCTAssertNotNil([session.contact lastNameFieldValue]);
}



@end
