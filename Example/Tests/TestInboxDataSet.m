//
//  TestInboxDataSet.m
//  ZingleSDK
//
//  Created by Jason Neel on 10/19/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGMockContactClient.h"
#import "ZingleSDK/ZNGContact.h"
#import "ZingleSDK/ZNGContactFieldValue.h"
#import "ZingleSDK/ZNGInboxDataSet.h"
#import "ZingleSDK/ZNGInboxDataUnconfirmed.h"

@interface TestInboxDataSet : XCTestCase

@end

@implementation TestInboxDataSet

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (ZNGContact *)randomContact
{
    ZNGContact * contact = [[ZNGContact alloc] init];
    u_int32_t number = arc4random() % 10000;
    
    ZNGContactFieldValue * firstName = [[ZNGContactFieldValue alloc] init];
    ZNGContactField * firstNameField = [[ZNGContactField alloc] init];
    firstNameField.displayName = @"First Name";
    firstName.customField = firstNameField;
    firstName.value = @"Contact";
    
    ZNGContactFieldValue * lastName = [[ZNGContactFieldValue alloc] init];
    ZNGContactField * lastNameField = [[ZNGContactField alloc] init];
    lastNameField.displayName = @"Last Name";
    lastName.customField = lastNameField;
    lastName.value = [NSString stringWithFormat:@"No. %u", number];
    
    contact.customFieldValues = @[firstName, lastName];
    
    contact.isClosed = arc4random() % 2;
    contact.isConfirmed = arc4random() % 2;
    
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidString = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    contact.contactId = (__bridge NSString *)uuidString;
    
    contact.createdAt = contact.updatedAt = [NSDate date];
    
    return contact;
}

- (void) testSingleContactRetrieval {
    ZNGContact * dude = [self randomContact];
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = @[dude];
    ZNGInboxDataSet * data = [[ZNGInboxDataSet alloc] initWithContactClient:contactClient];
    [data refresh];
    
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return [data.contacts containsObject:dude];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testPagination {
    NSMutableArray<ZNGContact *> * hundredsOfDudes = [[NSMutableArray alloc] initWithCapacity:100];
    
    for (int i=0; i < 100; i++) {
        [hundredsOfDudes addObject:[self randomContact]];
    }
    
    NSUInteger pageSize = 10;
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = hundredsOfDudes;
    ZNGInboxDataSet * data = [[ZNGInboxDataSet alloc] initWithContactClient:contactClient];
    data.pageSize = pageSize;
    [data refresh];
    
    NSArray<ZNGContact *> * expectedFirstPage = [hundredsOfDudes subarrayWithRange:NSMakeRange(0, pageSize)];

    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return [data.contacts.array isEqualToArray:expectedFirstPage];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    NSArray<ZNGContact *> * expectedFirstTwoPages = [hundredsOfDudes subarrayWithRange:NSMakeRange(0, (pageSize * 2))];
    
    // Grab a second page
    [data refreshStartingAtIndex:(pageSize * 1) removingTail:NO];
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return [data.contacts.array isEqualToArray:expectedFirstTwoPages];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"After refreshing second page, there are %llu contacts in data instead of the expected %lu", (unsigned long long)[data.contacts count], (pageSize * 2));
        }
    }];
}

/**
 *  Simulating: A contact goes from unconfirmed to confirmed in remote data.
 */
- (void) testRemoteConfirmedStatusChangeWithinAllData
{
    NSUInteger pageSize = 25;
    NSMutableArray<ZNGContact *> * fiftyDudes = [[NSMutableArray alloc] initWithCapacity:50];
    
    for (int i=0; i < 50; i++) {
        [fiftyDudes addObject:[self randomContact]];
    }
    
    // Pick someone in the rough middle of a page
    NSUInteger dudeIndex = 12;
    
    // Ensure he starts out unconfirmed
    ZNGContact * dude = fiftyDudes[dudeIndex];
    dude.isConfirmed = NO;
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = fiftyDudes;
    ZNGInboxDataSet * data = [[ZNGInboxDataSet alloc] initWithContactClient:contactClient];
    data.pageSize = pageSize;
    [data refresh];
    
    // Ensure he is indeed unconfirmed
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        for (ZNGContact * contact in data.contacts) {
            if ([contact isEqualToContact:dude]) {
                return !contact.isConfirmed;
            }
        }
        
        NSLog(@"Contact was not found in data.");
        return NO;
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    
    // Confirm him
    dude = [dude copy];
    dude.isConfirmed = YES;
    fiftyDudes = [fiftyDudes mutableCopy];
    [fiftyDudes replaceObjectAtIndex:dudeIndex withObject:dude];
    contactClient.contacts = fiftyDudes;
    
    // Ensure he is now confirmed
    [data refresh];
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        for (ZNGContact * contact in data.contacts) {
            if ([contact isEqualToContact:dude]) {
                return contact.isConfirmed;
            }
        }
        
        NSLog(@"Contact was not found after changing him to confirmed.");
        return NO;
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testContactDisappearedFromDataSet
{
    NSUInteger pageSize = 50;
    NSMutableArray<ZNGContact *> * fiftyDudes = [[NSMutableArray alloc] initWithCapacity:50];
    
    for (int i=0; i < 50; i++) {
        [fiftyDudes addObject:[self randomContact]];
    }
    
    // Pick someone in the rough middle of a page
    NSUInteger dudeIndex = 12;
    
    // Ensure he starts out unconfirmed
    ZNGContact * dude = fiftyDudes[dudeIndex];
    dude.isConfirmed = NO;
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = fiftyDudes;
    ZNGInboxDataUnconfirmed * data = [[ZNGInboxDataUnconfirmed alloc] initWithContactClient:contactClient];
    data.pageSize = pageSize;
    [data refresh];

    
    // Is he there?
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return [data.contacts containsObject:dude];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    
    // Confirm him
    dude = [dude copy];
    dude.isConfirmed = YES;
    fiftyDudes = [fiftyDudes mutableCopy];
    [fiftyDudes replaceObjectAtIndex:dudeIndex withObject:dude];
    contactClient.contacts = fiftyDudes;
    
    // Refresh
    [data refresh];
    
    
    // Make sure he is gone
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return ![data.contacts containsObject:dude];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/**
 *  Tests the ability for a contact to be modified locally in a way that will remove him from a data set and to have that reflected accurately before and after
 *   the server actually reflects that info.
 */
- (void) testSingleContactRemovedFromDataLocally
{
    NSUInteger pageSize = 50;
    NSMutableArray<ZNGContact *> * fiftyDudes = [[NSMutableArray alloc] initWithCapacity:50];
    
    for (int i=0; i < 50; i++) {
        [fiftyDudes addObject:[self randomContact]];
    }
    
    // Pick someone in the rough middle of a page
    NSUInteger dudeIndex = 12;
    
    // Ensure he starts out unconfirmed
    ZNGContact * dude = fiftyDudes[dudeIndex];
    dude.isConfirmed = NO;
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = fiftyDudes;
    ZNGInboxDataUnconfirmed * data = [[ZNGInboxDataUnconfirmed alloc] initWithContactClient:contactClient];
    data.pageSize = pageSize;
    [data refresh];
    
    
    // Is he there?
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return [data.contacts containsObject:dude];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    
    // Unconfirm him locally and make sure he is not there
    dude.isConfirmed = YES;
    [data contactWasChangedLocally:dude];
    
    XCTAssertFalse([data.contacts containsObject:dude]);
    
    
    // Now update the "remote data" and ensure that he did not magically reappear
    dude = [dude copy];
    dude.isConfirmed = YES;
    fiftyDudes = [fiftyDudes mutableCopy];
    [fiftyDudes replaceObjectAtIndex:dudeIndex withObject:dude];
    contactClient.contacts = fiftyDudes;
    [data refresh];
    
    XCTAssertTrue(data.loading);
    
    [self keyValueObservingExpectationForObject:data keyPath:@"loading" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return ((!data.loading) && (![data.contacts containsObject:dude]));
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/**
 *  If two contacts are both set from confirmed to unconfirmed one after another, the second contact may be set back to confirmed
 *   when data for the first contact is received.  This test reproduces this problem as seen in the wild in October 2016.
 */
- (void) testTwoContactsUpdatedLocallyInQuickSuccession
{
    NSUInteger pageSize = 50;
    NSMutableArray<ZNGContact *> * fiftyDudes = [[NSMutableArray alloc] initWithCapacity:50];
    
    for (int i=0; i < 50; i++) {
        [fiftyDudes addObject:[self randomContact]];
    }
    
    // Pick someone in the rough middle of a page
    NSUInteger dude1Index = 12;
    NSUInteger dude2Index = 13;
    
    // Ensure both start out unconfirmed
    ZNGContact * dude1 = fiftyDudes[dude1Index];
    dude1.isConfirmed = NO;
    ZNGContact * dude2 = fiftyDudes[dude2Index];
    dude2.isConfirmed = NO;
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = fiftyDudes;
    ZNGInboxDataSet * data = [[ZNGInboxDataSet alloc] initWithContactClient:contactClient];
    data.pageSize = pageSize;
    [data refresh];
    
    
    // Both should start out confirmed
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        __block BOOL dude1Unconfirmed = NO;
        __block BOOL dude2Unconfirmed = NO;
        
        [data.contacts enumerateObjectsUsingBlock:^(ZNGContact * _Nonnull contact, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([contact isEqual:dude1]) {
                dude1Unconfirmed = !contact.isConfirmed;
            } else if ([contact isEqual:dude2]) {
                dude2Unconfirmed = !contact.isConfirmed;
            }
            
            if (dude1Unconfirmed && dude2Unconfirmed) {
                *stop = YES;
            }
        }];
        
        return (dude1Unconfirmed && dude2Unconfirmed);
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    
    // Locally confirm dude #1
    dude1 = [dude1 copy];
    dude1.isConfirmed = YES;
    [data contactWasChangedLocally:dude1];
    dude1.updatedAt = [NSDate date];
    
    // Begin refresh
    [data refresh];
    
    // Locally confirm dude #2
    dude2 = [dude2 copy];
    dude2.isConfirmed = YES;
    dude2.updatedAt = [NSDate date];
    [data contactWasChangedLocally:dude2];
    
    // Wait for a KVO update
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:nil];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    // Ensure that dude #2 is not now magically unconfirmed again
    for (ZNGContact * contact in data.contacts) {
        if ([contact isEqual:dude2]) {
            XCTAssertTrue(contact.isConfirmed);
            break;
        }
    }
}

@end