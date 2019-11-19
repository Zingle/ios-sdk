//
//  TestContactSession.m
//  ZingleSDK
//
//  Created by Jason Neel on 10/26/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZingleSDK/ZingleSDK.h"
#import "ZingleSDK/ZingleContactSession.h"
#import "ZNGMockAccountClient.h"
#import "ZNGMockContactClient.h"
#import "ZNGMockServiceClient.h"
#import "ZNGMockContactServiceClient.h"
#import "ZNGMockUserAuthorizationClient.h"
#import "ZNGMockNotificationsClient.h"

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
    
    NSString * firebaseToken;
    
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
    
    firebaseToken = @"abcdefg-thisisatoken-55";
    
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
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1];
    session.serviceClient = serviceClient;
    
    ZNGMockContactServiceClient * contactServiceClient = [[ZNGMockContactServiceClient alloc] initWithSession:session];
    contactServiceClient.contactServices = @[contactService1];
    session.contactServiceClient = contactServiceClient;
    
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(availableContactServices)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        if ([session.availableContactServices count] > 0) {
            ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] initWithSession:session serviceId:self->contactService1.serviceId];
            contactClient.contact = self->me;
            
            session.contactClient = contactClient;
            session.contactService = self->contactService1;
            
            return YES;
        }
        
        return NO;
    }];
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(available)) expectedValue:@(YES)];
    
    [session connect];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testNotificationRegistration
{
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"aValue"];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockUserAuthorizationClient * authClient = [[ZNGMockUserAuthorizationClient alloc] initWithSession:session];
    authClient.contact = me;
    session.userAuthorizationClient = authClient;

    [ZingleSDK setFirebaseToken:firebaseToken];
    
    ZNGMockNotificationsClient * notificationsClient = [[ZNGMockNotificationsClient alloc] initWithSession:session];
    session.notificationsClient = notificationsClient;
    
    XCTAssertEqual(0, [notificationsClient.registeredServiceIds count], @"Mocked notifications client starts with no registrations.");
    
    ZNGMockAccountClient * accountClient = [[ZNGMockAccountClient alloc] initWithSession:session];
    accountClient.accounts = @[account1];
    session.accountClient = accountClient;
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1];
    session.serviceClient = serviceClient;
    
    ZNGMockContactServiceClient * contactServiceClient = [[ZNGMockContactServiceClient alloc] initWithSession:session];
    contactServiceClient.contactServices = @[contactService1];
    session.contactServiceClient = contactServiceClient;
    
    XCTestExpectation * connected = [self expectationWithDescription:@"Connected"];
    [self keyValueObservingExpectationForObject:notificationsClient keyPath:NSStringFromSelector(@selector(registeredServiceIds)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return [notificationsClient.registeredServiceIds containsObject:self->account1service1.serviceId];
    }];
    
    [session connectWithContactServiceChooser:^ZNGContactService * _Nullable(NSArray<ZNGContactService *> * _Nonnull availableContactServices) {
        ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] initWithSession:session serviceId:self->contactService1.serviceId];
        contactClient.contact = self->me;
        
        session.contactClient = contactClient;
        
        return self->contactService1;
    } completion:^(ZNGContactService * _Nullable contactService, ZNGService * _Nullable service, ZNGError * _Nullable error) {
        if (([contactService isEqual:self->contactService1]) && (error == nil)) {
            [connected fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testLogoutRemovesNotification
{
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"aValue"];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockUserAuthorizationClient * authClient = [[ZNGMockUserAuthorizationClient alloc] initWithSession:session];
    authClient.contact = me;
    session.userAuthorizationClient = authClient;
    
    [ZingleSDK setFirebaseToken:firebaseToken];
    
    ZNGMockNotificationsClient * notificationsClient = [[ZNGMockNotificationsClient alloc] initWithSession:session];
    session.notificationsClient = notificationsClient;
    
    XCTAssertEqual(0, [notificationsClient.registeredServiceIds count], @"Mocked notifications client starts with no registrations.");
    
    ZNGMockAccountClient * accountClient = [[ZNGMockAccountClient alloc] initWithSession:session];
    accountClient.accounts = @[account1];
    session.accountClient = accountClient;
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1];
    session.serviceClient = serviceClient;
    
    ZNGMockContactServiceClient * contactServiceClient = [[ZNGMockContactServiceClient alloc] initWithSession:session];
    contactServiceClient.contactServices = @[contactService1];
    session.contactServiceClient = contactServiceClient;
    
    XCTestExpectation * connected = [self expectationWithDescription:@"Connected"];
    [self keyValueObservingExpectationForObject:notificationsClient keyPath:NSStringFromSelector(@selector(registeredServiceIds)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return [notificationsClient.registeredServiceIds containsObject:self->account1service1.serviceId];
    }];
    
    [session connectWithContactServiceChooser:^ZNGContactService * _Nullable(NSArray<ZNGContactService *> * _Nonnull availableContactServices) {
        ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] initWithSession:session serviceId:self->contactService1.serviceId];
        contactClient.contact = self->me;
        
        session.contactClient = contactClient;
        
        return self->contactService1;
    } completion:^(ZNGContactService * _Nullable contactService, ZNGService * _Nullable service, ZNGError * _Nullable error) {
        if (([contactService isEqual:self->contactService1]) && (error == nil)) {
            [connected fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    [self keyValueObservingExpectationForObject:notificationsClient keyPath:NSStringFromSelector(@selector(registeredServiceIds)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return ![notificationsClient.registeredServiceIds containsObject:self->account1service1.serviceId];
    }];
    
    [session logout];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testSuccessfulSingleContactSessionWithContactSelectionBlock
{
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"aValue"];
    
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
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1];
    session.serviceClient = serviceClient;
    
    ZNGMockContactServiceClient * contactServiceClient = [[ZNGMockContactServiceClient alloc] initWithSession:session];
    contactServiceClient.contactServices = @[contactService1];
    session.contactServiceClient = contactServiceClient;
    
    XCTestExpectation * contactSelectionBlockCalled = [self expectationWithDescription:@"Contact selection block called"];
    XCTestExpectation * connected = [self expectationWithDescription:@"Connection completed"];

    
    [session connectWithContactServiceChooser:^ZNGContactService * _Nullable(NSArray<ZNGContactService *> * _Nonnull availableContactServices) {
        [contactSelectionBlockCalled fulfill];
        XCTAssertEqual([availableContactServices firstObject], self->contactService1);
        
        ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] initWithSession:session serviceId:self->contactService1.serviceId];
        contactClient.contact = self->me;
        
        session.contactClient = contactClient;
        
        return self->contactService1;
    } completion:^(ZNGContactService * _Nullable contactService, ZNGService * _Nullable service, ZNGError * _Nullable error) {
        if (([contactService isEqual:self->contactService1]) && (error == nil)) {
            [connected fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/**
 *  Connect using the contact selection completion block
 */
- (void) testSuccessfulSingleContactSessionWithCompletionBlock
{
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"aValue"];
    
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
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1];
    session.serviceClient = serviceClient;
    
    ZNGMockContactServiceClient * contactServiceClient = [[ZNGMockContactServiceClient alloc] initWithSession:session];
    contactServiceClient.contactServices = @[contactService1];
    session.contactServiceClient = contactServiceClient;
    
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(availableContactServices)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return [session.availableContactServices isEqualToArray:@[self->contactService1]];
    }];
    
    [session connect];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    XCTestExpectation * connected = [self expectationWithDescription:@"Connection completed"];
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] initWithSession:session serviceId:contactService1.serviceId];
    contactClient.contact = me;
    
    session.contactClient = contactClient;
    
    [session setContactService:contactService1 completion:^(ZNGContactService * _Nullable contactService, ZNGService * _Nullable service, ZNGError * _Nullable error) {
        if (([contactService isEqual:self->contactService1]) && (error == nil)) {
            [connected fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/**
 *  Observe the available flag instead of relying on the completion block
 */
- (void) testSuccessfulSingleContactSessionViaKVO
{
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"aValue"];
    
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
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1];
    session.serviceClient = serviceClient;
    
    ZNGMockContactServiceClient * contactServiceClient = [[ZNGMockContactServiceClient alloc] initWithSession:session];
    contactServiceClient.contactServices = @[contactService1];
    session.contactServiceClient = contactServiceClient;
    
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(availableContactServices)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return [session.availableContactServices isEqualToArray:@[self->contactService1]];
    }];
    
    [session connect];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(available)) expectedValue:@(YES)];
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] initWithSession:session serviceId:contactService1.serviceId];
    contactClient.contact = me;
    
    session.contactClient = contactClient;
    session.contactService = contactService1;
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testMultipleContactSessions
{
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"aValue"];
    
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
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1];
    session.serviceClient = serviceClient;
    
    ZNGMockContactServiceClient * contactServiceClient = [[ZNGMockContactServiceClient alloc] initWithSession:session];
    NSArray<ZNGContactService *> * contactServices = @[contactService1, contactService2];
    contactServiceClient.contactServices = contactServices;
    session.contactServiceClient = contactServiceClient;
    
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(availableContactServices)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return [session.availableContactServices isEqualToArray:contactServices];
    }];
    
    [session connect];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(available)) expectedValue:@(YES)];
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] initWithSession:session serviceId:contactService1.serviceId];
    contactClient.contact = me;
    
    session.contactClient = contactClient;
    session.contactService = contactService1;
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testContactServiceChoosingBlock
{
    XCTestExpectation * contactServiceChooserExpectation = [self expectationWithDescription:@"Contact chooser block is called"];
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"aValue"];
    session.contactServiceChooser = ^ZNGContactService * _Nullable(NSArray<ZNGContactService *> * _Nonnull availableContactServices) {
        [contactServiceChooserExpectation fulfill];
        return self->contactService1;
    };
    
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
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1];
    session.serviceClient = serviceClient;
    
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
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"avalue"];
    session.errorHandler = ^(ZNGError * _Nonnull error) {
        [errorBlockCalledExpectation fulfill];
    };
    
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
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"aValue"];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    // Remove first name and last name fields to ensure the contact session is enforcing their existence
    ZNGContact * contact = [me copy];
    contact.customFieldValues = @[];

    
    ZNGMockUserAuthorizationClient * authClient = [[ZNGMockUserAuthorizationClient alloc] initWithSession:session];
    authClient.contact = contact;
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
            session.contactService = self->contactService1;
            return YES;
        }
        
        return NO;
    }];
    
    [session connect];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(available)) expectedValue:@(YES)];

    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] initWithSession:session serviceId:contactService1.serviceId];
    contactClient.contact = contact;
    
    session.contactClient = contactClient;
    session.contactService = contactService1;
    
    [self keyValueObservingExpectationForObject:session keyPath:@"contact.customFieldValues" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return (([session.contact firstNameFieldValue] != nil) && ([session.contact lastNameFieldValue] != nil));
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testAllDataAvailableWhenAvailableFlagSet
{
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"aValue"];
    
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
            session.contactService = self->contactService1;
            return YES;
        }
        
        return NO;
    }];
    
    [session connect];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(available)) expectedValue:@(YES)];
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] initWithSession:session serviceId:contactService1.serviceId];
    contactClient.contact = me;
    
    session.contactClient = contactClient;
    session.contactService = contactService1;
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    XCTAssertNotNil(session.contactService);
    XCTAssertNotNil(session.contact);
    XCTAssertNotNil(session.conversation);
    XCTAssertNotNil(session.service);
}

- (void) testPushNotifcationTriggersServiceRefresh
{
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"aValue"];
    
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
    
    XCTestExpectation * connected = [self expectationWithDescription:@"Connected successfully"];
    
    [session connectWithContactServiceChooser:^ZNGContactService * _Nullable(NSArray<ZNGContactService *> * _Nonnull availableContactServices) {
        ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] initWithSession:session serviceId:self->contactService1.serviceId];
        contactClient.contact = self->me;
        
        session.contactClient = contactClient;
        
        serviceClient.throwExceptionOnAnyServiceRequest = NO;
        
        return self->contactService1;
    } completion:^(ZNGContactService * _Nullable contactService, ZNGService * _Nullable service, ZNGError * _Nullable error) {
        if ([contactService isEqual:self->contactService1]) {
            [connected fulfill];
        } else {
            XCTFail(@"Contact service was not %@ as expected.  Contact service: %@, service: %@, error: %@",
                    self->contactService1.serviceId, contactService.serviceId, service.serviceId, error);
        }
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    
    XCTestExpectation * serviceRefreshedExpectation = [self expectationWithDescription:@"Service was refreshed due to push notification"];
    serviceClient.serviceRequestedExpectation = serviceRefreshedExpectation;
    
    NSDictionary * userInfo = @{ @"aps" : @{ @"service" : contactService1.serviceId } };
    [[NSNotificationCenter defaultCenter] postNotificationName:ZNGPushNotificationReceived object:nil userInfo:userInfo];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testIrrelevantPushNotificationDoesNotTriggerRefresh
{
    ZingleContactSession * session = [[ZingleContactSession alloc] initWithToken:@"token" key:@"key" channelTypeId:@"anID" channelValue:@"aValue"];
    
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
    
    XCTestExpectation * connected = [self expectationWithDescription:@"Connected successfully"];
    
    [session connectWithContactServiceChooser:^ZNGContactService * _Nullable(NSArray<ZNGContactService *> * _Nonnull availableContactServices) {
        ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] initWithSession:session serviceId:self->contactService1.serviceId];
        contactClient.contact = self->me;
        
        session.contactClient = contactClient;
        
        return self->contactService1;
    } completion:^(ZNGContactService * _Nullable contactService, ZNGService * _Nullable service, ZNGError * _Nullable error) {
        if ([contactService isEqual:self->contactService1]) {
            [connected fulfill];
        } else {
            XCTFail(@"Contact service was not %@ as expected.  Contact service: %@, service: %@, error: %@",
                    self->contactService1.serviceId, contactService.serviceId, service.serviceId, error);
        }
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    serviceClient.throwExceptionOnAnyServiceRequest = YES;
    NSDictionary * userInfo = @{ @"aps" : @{ @"service" : contactService2.serviceId } };
    [[NSNotificationCenter defaultCenter] postNotificationName:ZNGPushNotificationReceived object:nil userInfo:userInfo];
    
    
    // Wait a couple of seconds to ensure that we do not call service client and throw an exception
    XCTestExpectation * waitedForExceptionSuccessfully = [self expectationWithDescription:@"Waited for an exception to be thrown from an errant service request without one being thrown."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:1.0];
        [waitedForExceptionSuccessfully fulfill];
    });
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    serviceClient.throwExceptionOnAnyServiceRequest = NO;
}

@end
