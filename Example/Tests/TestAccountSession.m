//
//  TestAccountSession.m
//  ZingleSDK
//
//  Created by Jason Neel on 11/3/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZingleSDK/ZingleSDK.h"
#import "ZingleSDK/ZingleAccountSession.h"
#import "ZNGMockAccountClient.h"
#import "ZNGMockContactClient.h"
#import "ZNGMockNotificationsClient.h"
#import "ZNGMockServiceClient.h"
#import "ZNGMockUserAuthorizationClient.h"
#import "ZNGMockUserClient.h"
@import CocoaLumberjack;

@interface TestAccountSession : XCTestCase

@end

@implementation TestAccountSession
{
    NSData * deviceToken;
    
    ZNGService * account1service1;
    ZNGService * account2service1;
    ZNGService * account2service2;
    ZNGAccount * account1;
    ZNGAccount * account2;
    
    ZNGContact * contact1;
    ZNGUser * user1;
}

- (void)setUp
{
    [super setUp];
    
    // Console logging
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    
    // File names of the test data in our bundle
    NSString * account1FileName = @"devTestAccount";
    NSString * account2FileName = @"luisTestAccount";
    NSString * service1FileName = @"devEnterpriseService";
    NSString * service2FileName = @"luisTestService";
    NSString * service3FileName = @"luisIOSTest";
    
    NSString * deviceTokenString = @"123456789abcdef123456789abcdef";
    deviceToken = [deviceTokenString dataUsingEncoding:NSUTF8StringEncoding];
    
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
    
    
    contact1 = [[ZNGContact alloc] init];
    
    ZNGContactFieldValue * firstName = [[ZNGContactFieldValue alloc] init];
    ZNGContactField * firstNameField = [[ZNGContactField alloc] init];
    firstNameField.displayName = @"First Name";
    firstName.value = @"Me";
    firstName.customField = firstNameField;
    
    ZNGContactFieldValue * lastName = [[ZNGContactFieldValue alloc] init];
    ZNGContactField * lastNameField = [[ZNGContactField alloc] init];
    lastNameField.displayName = @"Last Name";
    lastName.value = @"McMoi";
    lastName.customField = lastNameField;
    
    contact1.customFieldValues = @[firstName, lastName];
    contact1.contactId = @"00000000-0000-0000-0000-1234abcd1234";
    
    
    user1 = [[ZNGUser alloc] init];
    user1.firstName = [[contact1 firstNameFieldValue] value];
    user1.lastName = [[contact1 lastNameFieldValue] value];
    user1.userId = contact1.contactId;
}

- (void) testSingleAccountSingleServiceLogin
{
    ZingleAccountSession * session = [ZingleSDK accountSessionWithToken:@"token" key:@"key"];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockAccountClient * accountClient = [[ZNGMockAccountClient alloc] initWithSession:session];
    accountClient.accounts = @[account1];
    session.accountClient = accountClient;
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1];
    session.serviceClient = serviceClient;
    
    ZNGMockUserAuthorizationClient * userAuthClient = [[ZNGMockUserAuthorizationClient alloc] initWithSession:session];
    userAuthClient.contact = contact1;
    userAuthClient.authorizationClass = @"account";
    session.userAuthorizationClient = userAuthClient;
    
    ZNGMockUserClient * userClient = [[ZNGMockUserClient alloc] initWithSession:session accountId:account1.accountId];
    userClient.user = user1;
    session.userClient = userClient;
    
    XCTestExpectation * connected = [self expectationWithDescription:@"Connected successfully"];
    
    [session connectWithAccountChooser:^ZNGAccount * _Nullable(NSArray<ZNGAccount *> * _Nonnull availableAccounts) {
        XCTFail(@"Account chooesr was called even though we only expect one account.  It gave ue %llu choices.", (unsigned long long)[availableAccounts count]);
        return nil;
    } serviceChooser:^ZNGService * _Nullable(NSArray<ZNGService *> * _Nonnull availableServices) {
        XCTFail(@"Service chooser was called even though we only expect one service.  It gave us %llu choices.", (unsigned long long)[availableServices count]);
        return nil;
    } completion:^(ZNGService * _Nullable service, ZNGError * _Nullable error) {
        XCTAssertNotNil(service, @"Service should not be nil");
        XCTAssertNil(error, @"Error should be nil");
        [connected fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testAccountChooserBlock
{
    ZingleAccountSession * session = [ZingleSDK accountSessionWithToken:@"token" key:@"key"];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockAccountClient * accountClient = [[ZNGMockAccountClient alloc] initWithSession:session];
    accountClient.accounts = @[account1, account2];
    session.accountClient = accountClient;
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1, account2service1, account2service2];
    session.serviceClient = serviceClient;
    
    XCTestExpectation * accountChooserCalled = [self expectationWithDescription:@"Account chooser block called"];
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(account)) expectedValue:account1];
    
    [session connectWithAccountChooser:^ZNGAccount * _Nullable(NSArray<ZNGAccount *> * _Nonnull availableAccounts) {
        XCTAssertEqualObjects(availableAccounts, accountClient.accounts, @"Account chooser block provides the expected account choices.");
        [accountChooserCalled fulfill];
        return account1;
    } serviceChooser:nil completion:nil];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testServiceChooserBlock
{
    ZingleAccountSession * session = [ZingleSDK accountSessionWithToken:@"token" key:@"key"];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockAccountClient * accountClient = [[ZNGMockAccountClient alloc] initWithSession:session];
    accountClient.accounts = @[account2];
    session.accountClient = accountClient;
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account2service1, account2service2];
    session.serviceClient = serviceClient;
    
    ZNGMockUserAuthorizationClient * userAuthClient = [[ZNGMockUserAuthorizationClient alloc] initWithSession:session];
    userAuthClient.contact = contact1;
    userAuthClient.authorizationClass = @"account";
    session.userAuthorizationClient = userAuthClient;
    
    ZNGMockUserClient * userClient = [[ZNGMockUserClient alloc] initWithSession:session accountId:account2.accountId];
    userClient.user = user1;
    session.userClient = userClient;
    
    XCTestExpectation * serviceChooserCalled = [self expectationWithDescription:@"Service chooser block called"];
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(service)) expectedValue:account2service1];
    [self keyValueObservingExpectationForObject:session keyPath:NSStringFromSelector(@selector(available)) expectedValue:@YES];
    
    [session connectWithAccountChooser:^ZNGAccount * _Nullable(NSArray<ZNGAccount *> * _Nonnull availableAccounts) {
        XCTFail(@"Account chooser called even though we only expect one available account.  We were given %llu accounts.", (unsigned long long)[availableAccounts count]);
        return nil;
    } serviceChooser:^ZNGService * _Nullable(NSArray<ZNGService *> * _Nonnull availableServices) {
        NSSet * availableServicesSet = [NSSet setWithArray:availableServices];
        NSSet * expectedServicesSet = [NSSet setWithArray:serviceClient.services];
        XCTAssertEqualObjects(availableServicesSet, expectedServicesSet, @"Service chooser block provides expected services.");
        [serviceChooserCalled fulfill];
        return account2service1;
    } completion:nil];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testUserAuthorizationAndUserInfoAvailableImmediately
{
    ZingleAccountSession * session = [ZingleSDK accountSessionWithToken:@"token" key:@"key"];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockAccountClient * accountClient = [[ZNGMockAccountClient alloc] initWithSession:session];
    accountClient.accounts = @[account1];
    session.accountClient = accountClient;
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1];
    session.serviceClient = serviceClient;
    
    ZNGMockUserAuthorizationClient * userAuthClient = [[ZNGMockUserAuthorizationClient alloc] initWithSession:session];
    userAuthClient.contact = contact1;
    userAuthClient.authorizationClass = @"account";
    session.userAuthorizationClient = userAuthClient;
    
    ZNGMockUserClient * userClient = [[ZNGMockUserClient alloc] initWithSession:session accountId:account1.accountId];
    userClient.user = user1;
    session.userClient = userClient;
    
    XCTestExpectation * connected = [self expectationWithDescription:@"Connected successfully"];
    
    [session connectWithCompletion:^(ZNGService * _Nullable service, ZNGError * _Nullable error) {
        [connected fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    XCTAssertNotNil([session.userAuthorization displayName], @"Authenticated user information (ZNGUserAuthorization) should be available on login.");
    XCTAssertNotNil(session.user.userId, @"User information (ZNGUser) should be available on login.");
}

- (void) testRegisteredForPushNotifications
{
    ZingleAccountSession * session = [ZingleSDK accountSessionWithToken:@"token" key:@"key"];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockAccountClient * accountClient = [[ZNGMockAccountClient alloc] initWithSession:session];
    accountClient.accounts = @[account1];
    session.accountClient = accountClient;
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1];
    session.serviceClient = serviceClient;
    
    ZNGMockNotificationsClient * notificationsClient = [[ZNGMockNotificationsClient alloc] initWithSession:session];
    session.notificationsClient = notificationsClient;
    
    ZNGMockUserAuthorizationClient * userAuthClient = [[ZNGMockUserAuthorizationClient alloc] initWithSession:session];
    userAuthClient.contact = contact1;
    userAuthClient.authorizationClass = @"account";
    session.userAuthorizationClient = userAuthClient;
    
    ZNGMockUserClient * userClient = [[ZNGMockUserClient alloc] initWithSession:session accountId:account1.accountId];
    userClient.user = user1;
    session.userClient = userClient;
    
    [ZingleSDK setPushNotificationDeviceToken:deviceToken];
    
    XCTestExpectation * connected = [self expectationWithDescription:@"Connected successfully"];
    [self keyValueObservingExpectationForObject:notificationsClient keyPath:NSStringFromSelector(@selector(registeredServiceIds)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return (([notificationsClient.registeredServiceIds count] == 1) && ([notificationsClient.registeredServiceIds containsObject:account1service1.serviceId]));
    }];
    
    XCTAssertEqual(0, [notificationsClient.registeredServiceIds count], @"Mocked notifications client starts with no registrations.");
    [session connectWithCompletion:^(ZNGService * _Nullable service, ZNGError * _Nullable error) {
        XCTAssertNotNil(session, @"Session is non nil in connect completion block");
        XCTAssertNil(error, @"Error is nil in connect completion block");
        [connected fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testLogoutRemovesPushNotificationSubscription
{
    ZingleAccountSession * session = [ZingleSDK accountSessionWithToken:@"token" key:@"key"];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockAccountClient * accountClient = [[ZNGMockAccountClient alloc] initWithSession:session];
    accountClient.accounts = @[account1];
    session.accountClient = accountClient;
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1];
    session.serviceClient = serviceClient;
    
    ZNGMockNotificationsClient * notificationsClient = [[ZNGMockNotificationsClient alloc] initWithSession:session];
    session.notificationsClient = notificationsClient;
    
    ZNGMockUserAuthorizationClient * userAuthClient = [[ZNGMockUserAuthorizationClient alloc] initWithSession:session];
    userAuthClient.contact = contact1;
    userAuthClient.authorizationClass = @"account";
    session.userAuthorizationClient = userAuthClient;
    
    ZNGMockUserClient * userClient = [[ZNGMockUserClient alloc] initWithSession:session accountId:account1.accountId];
    userClient.user = user1;
    session.userClient = userClient;
    
    [ZingleSDK setPushNotificationDeviceToken:deviceToken];
    
    XCTestExpectation * connected = [self expectationWithDescription:@"Connected successfully"];
    [self keyValueObservingExpectationForObject:notificationsClient keyPath:NSStringFromSelector(@selector(registeredServiceIds)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return (([notificationsClient.registeredServiceIds count] == 1) && ([notificationsClient.registeredServiceIds containsObject:account1service1.serviceId]));
    }];
    
    XCTAssertEqual(0, [notificationsClient.registeredServiceIds count], @"Mocked notifications client starts with no registrations.");
    [session connectWithCompletion:^(ZNGService * _Nullable service, ZNGError * _Nullable error) {
        XCTAssertNotNil(session, @"Session is non nil in connect completion block");
        XCTAssertNil(error, @"Error is nil in connect completion block");
        [connected fulfill];
    }];
    
    // Wait for login to complete and notification registration to take place
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    // Now log off and ensure that push notification registration is gone
    [self keyValueObservingExpectationForObject:notificationsClient keyPath:NSStringFromSelector(@selector(registeredServiceIds)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return ([notificationsClient.registeredServiceIds count] == 0);
    }];
    
    [session logout];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testRelevantPushNotifcationTriggersServiceRefresh
{
    ZingleAccountSession * session = [ZingleSDK accountSessionWithToken:@"token" key:@"key"];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockAccountClient * accountClient = [[ZNGMockAccountClient alloc] initWithSession:session];
    accountClient.accounts = @[account1];
    session.accountClient = accountClient;
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1];
    session.serviceClient = serviceClient;
    
    ZNGMockUserAuthorizationClient * userAuthClient = [[ZNGMockUserAuthorizationClient alloc] initWithSession:session];
    userAuthClient.contact = contact1;
    userAuthClient.authorizationClass = @"account";
    session.userAuthorizationClient = userAuthClient;
    
    ZNGMockUserClient * userClient = [[ZNGMockUserClient alloc] initWithSession:session accountId:account1.accountId];
    userClient.user = user1;
    session.userClient = userClient;
    
    XCTestExpectation * connected = [self expectationWithDescription:@"Connected successfully"];
    
    [session connectWithAccountChooser:nil serviceChooser:nil completion:^(ZNGService * _Nullable service, ZNGError * _Nullable error) {
        if ([service isEqual:account1service1]) {
            [connected fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    
    XCTestExpectation * serviceRefreshedExpectation = [self expectationWithDescription:@"Service was refreshed due to push notification"];
    serviceClient.serviceRequestedExpectation = serviceRefreshedExpectation;
    
    NSDictionary * userInfo = @{ @"aps" : @{ @"service" : account1service1.serviceId } };
    [[NSNotificationCenter defaultCenter] postNotificationName:ZNGPushNotificationReceived object:nil userInfo:userInfo];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testIrrelevantPushNotificationDoesNotTriggerServiceRequest
{
    ZingleAccountSession * session = [ZingleSDK accountSessionWithToken:@"token" key:@"key"];
    
    // Set the HTTP client to nil to prevent reaching out through the internet tubes if we forget to stub something
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    session.sessionManager = nil;
#pragma clang diagnostic pop
    
    ZNGMockAccountClient * accountClient = [[ZNGMockAccountClient alloc] initWithSession:session];
    accountClient.accounts = @[account1];
    session.accountClient = accountClient;
    
    ZNGMockServiceClient * serviceClient = [[ZNGMockServiceClient alloc] initWithSession:session];
    serviceClient.services = @[account1service1];
    session.serviceClient = serviceClient;
    
    ZNGMockUserAuthorizationClient * userAuthClient = [[ZNGMockUserAuthorizationClient alloc] initWithSession:session];
    userAuthClient.contact = contact1;
    userAuthClient.authorizationClass = @"account";
    session.userAuthorizationClient = userAuthClient;
    
    ZNGMockUserClient * userClient = [[ZNGMockUserClient alloc] initWithSession:session accountId:account1.accountId];
    userClient.user = user1;
    session.userClient = userClient;
    
    XCTestExpectation * connected = [self expectationWithDescription:@"Connected successfully"];
    
    [session connectWithAccountChooser:nil serviceChooser:nil completion:^(ZNGService * _Nullable service, ZNGError * _Nullable error) {
        if ([service isEqual:account1service1]) {
            [connected fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    
    XCTestExpectation * waitedLongEnough = [self expectationWithDescription:@"Enough time passed that we can be sure the notification did not trigger an unneeded refresh"];
    
    serviceClient.throwExceptionOnAnyServiceRequest = YES;
    NSDictionary * userInfo = @{ @"aps" : @{ @"service" : account2service2.serviceId } };   // A different service
    [[NSNotificationCenter defaultCenter] postNotificationName:ZNGPushNotificationReceived object:nil userInfo:userInfo];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:1.0];
        [waitedLongEnough fulfill];
    });
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}


@end
