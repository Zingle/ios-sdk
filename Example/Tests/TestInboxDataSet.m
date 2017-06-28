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
#import "ZingleSDK/ZNGContactDataSetBuilder.h"

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

/**
 *  Returns an array of one hundred ZNGContacts.
 *  Contacts at indexes divisible by 2 will be confirmed.
 *  Contacts at indexes divisible by 3 will be closed.
 */
- (NSArray<ZNGContact *> *) oneHundredDudes
{
    NSUInteger numDudes = 100;
    NSMutableArray<ZNGContact *> * dudes = [[NSMutableArray alloc] initWithCapacity:numDudes];
    
    ZNGContactFieldValue * firstName = [[ZNGContactFieldValue alloc] init];
    ZNGContactField * firstNameField = [[ZNGContactField alloc] init];
    firstNameField.displayName = @"First Name";
    firstName.customField = firstNameField;
    firstName.value = @"Contact";
    
    for (NSUInteger i=0; i < numDudes; i++) {
        ZNGContact * dude = [[ZNGContact alloc] init];
        dude.isConfirmed = ((i % 2) == 0);
        
        ZNGContactFieldValue * lastName = [[ZNGContactFieldValue alloc] init];
        ZNGContactField * lastNameField = [[ZNGContactField alloc] init];
        lastNameField.displayName = @"Last Name";
        lastName.customField = lastNameField;
        lastName.value = [NSString stringWithFormat:@"No. %llu", (unsigned long long)i];
        
        dude.customFieldValues = @[[firstName copy], lastName];
        
        // Fake UUID of the form 00000000-0000-0000-0000-000000000000 with the contact's index in hex.
        dude.contactId = [NSString stringWithFormat:@"00000000-0000-0000-0000-%012llx", (unsigned long long)i];
        
        [dudes addObject:dude];
    }
    
    return dudes;
}

- (void) testSingleContactRetrieval {
    ZNGContact * dude = [[self oneHundredDudes] firstObject];
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = @[dude];
    ZNGInboxDataSet * data = [ZNGInboxDataSet dataSetWithBlock:^(ZNGContactDataSetBuilder * _Nonnull builder) {
        builder.contactClient = contactClient;
    }];
    [data refresh];
    
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return [data.contacts containsObject:dude];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testPagination {
    NSArray<ZNGContact *> * hundredsOfDudes = [self oneHundredDudes];
    
    NSUInteger pageSize = 10;
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = hundredsOfDudes;
    
    ZNGInboxDataSet * data = [ZNGInboxDataSet dataSetWithBlock:^(ZNGContactDataSetBuilder * _Nonnull builder) {
        builder.contactClient = contactClient;
        builder.pageSize = pageSize;
    }];
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
    NSMutableArray<ZNGContact *> * oneHundredDudes = [[self oneHundredDudes] mutableCopy];
    
    // Pick someone in the rough middle of a page
    NSUInteger dudeIndex = 12;
    
    // Ensure he starts out unconfirmed
    ZNGContact * dude = oneHundredDudes[dudeIndex];
    dude.isConfirmed = NO;
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = oneHundredDudes;
    ZNGInboxDataSet * data = [ZNGInboxDataSet dataSetWithBlock:^(ZNGContactDataSetBuilder * _Nonnull builder) {
        builder.contactClient = contactClient;
        builder.pageSize = pageSize;
    }];
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
    dude.updatedAt = [NSDate date];
    oneHundredDudes = [oneHundredDudes mutableCopy];
    [oneHundredDudes replaceObjectAtIndex:dudeIndex withObject:dude];
    contactClient.contacts = oneHundredDudes;
    
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
    NSMutableArray<ZNGContact *> * oneHundredDudes = [[self oneHundredDudes] mutableCopy];
    
    // Pick someone in the rough middle of a page
    NSUInteger dudeIndex = 11;
    
    // Ensure he starts out unconfirmed
    ZNGContact * dude = oneHundredDudes[dudeIndex];
    dude.isConfirmed = NO;
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = oneHundredDudes;
    ZNGInboxDataSet * data = [ZNGInboxDataSet dataSetWithBlock:^(ZNGContactDataSetBuilder * _Nonnull builder) {
        builder.contactClient = contactClient;
        builder.unconfirmed = YES;
        builder.pageSize = pageSize;
    }];
    [data refresh];

    
    // Is he there?
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return [data.contacts containsObject:dude];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    
    // Confirm him
    dude = [dude copy];
    dude.isConfirmed = YES;
    oneHundredDudes = [oneHundredDudes mutableCopy];
    [oneHundredDudes replaceObjectAtIndex:dudeIndex withObject:dude];
    contactClient.contacts = oneHundredDudes;
    
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
    NSMutableArray<ZNGContact *> * oneHundredDudes = [[self oneHundredDudes] mutableCopy];

    
    // Pick someone in the rough middle of a page
    NSUInteger dudeIndex = 11;
    
    // Ensure he starts out unconfirmed
    ZNGContact * dude = oneHundredDudes[dudeIndex];
    dude.isConfirmed = NO;
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = oneHundredDudes;
    ZNGInboxDataSet * data = [ZNGInboxDataSet dataSetWithBlock:^(ZNGContactDataSetBuilder * _Nonnull builder) {
        builder.contactClient = contactClient;
        builder.unconfirmed = YES;
        builder.pageSize = pageSize;
    }];
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
    oneHundredDudes = [oneHundredDudes mutableCopy];
    [oneHundredDudes replaceObjectAtIndex:dudeIndex withObject:dude];
    contactClient.contacts = oneHundredDudes;
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
    NSMutableArray<ZNGContact *> * twoDudes = [[[self oneHundredDudes] subarrayWithRange:NSMakeRange(0, 2)] mutableCopy];
    
    NSUInteger dude1Index = 0;
    NSUInteger dude2Index = 1;
    
    // Ensure both start out unconfirmed
    ZNGContact * dude1 = twoDudes[dude1Index];
    dude1.isConfirmed = NO;
    ZNGContact * dude2 = twoDudes[dude2Index];
    dude2.isConfirmed = NO;
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = twoDudes;
    ZNGInboxDataSet * data = [ZNGInboxDataSet dataSetWithBlock:^(ZNGContactDataSetBuilder * _Nonnull builder) {
        builder.contactClient = contactClient;
        builder.pageSize = pageSize;
    }];
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
    twoDudes = [twoDudes mutableCopy];
    [twoDudes replaceObjectAtIndex:dude1Index withObject:dude1];
    contactClient.contacts = twoDudes;
    
    // Begin refresh
    [data refresh];
    
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        for (ZNGContact * contact in data.contacts) {
            if ([contact isEqualToContact:dude1]) {
                return dude1.isConfirmed;
            }
        }
        
        return NO;
    }];
    
    // Locally confirm dude #2
    dude2 = [dude2 copy];
    dude2.isConfirmed = YES;
    [data contactWasChangedLocally:dude2];
    
    // Wait for a KVO update
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    // Ensure that dude #2 is not now magically unconfirmed again due to remote data coming in and overwriting out local change
    for (ZNGContact * contact in data.contacts) {
        if ([contact isEqual:dude2]) {
            XCTAssertTrue(contact.isConfirmed);
            break;
        }
    }
}

- (void) testContactMovedDown
{
    NSUInteger pageSize = 200;
    NSMutableArray<ZNGContact *> * oneHundredDudes = [[self oneHundredDudes] mutableCopy];
    
    // Pick someone in the rough middle of a page
    NSUInteger dudeIndex = 11;
    ZNGContact * dude = oneHundredDudes[dudeIndex];
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = oneHundredDudes;
    
    ZNGInboxDataSet * data = [ZNGInboxDataSet dataSetWithBlock:^(ZNGContactDataSetBuilder * _Nonnull builder) {
        builder.contactClient = contactClient;
        builder.pageSize = pageSize;
    }];
    [data refresh];
    
    
    // Is he there?
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return [data.contacts containsObject:dude];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    
    // Move him down
    [oneHundredDudes removeObjectAtIndex:dudeIndex];
    [oneHundredDudes addObject:dude];
    
    // Refresh
    [data refresh];
    
    
    // Make sure he is at the bottom
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return ([data.contacts indexOfObject:dude] == ([data.contacts count] - 1));
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testOneDudeDownOneDudeUp
{
    NSUInteger pageSize = 200;
    NSMutableArray<ZNGContact *> * oneHundredDudes = [[self oneHundredDudes] mutableCopy];
    
    NSUInteger willMoveToHeadDudeIndex = 11;
    ZNGContact * willMoveToHeadDude = oneHundredDudes[willMoveToHeadDudeIndex];
    NSUInteger willMoveDownToIndex = 50;
    ZNGContact * willMoveDownDude = [oneHundredDudes firstObject];
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = oneHundredDudes;
    
    ZNGInboxDataSet * data = [ZNGInboxDataSet dataSetWithBlock:^(ZNGContactDataSetBuilder * _Nonnull builder) {
        builder.contactClient = contactClient;
        builder.pageSize = pageSize;
    }];

    [data refresh];
    
    
    // Are they there?
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return ([data.contacts containsObject:willMoveToHeadDude] && [data.contacts containsObject:willMoveDownDude]);
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    // Move the dudes
    [oneHundredDudes removeObjectAtIndex:willMoveToHeadDudeIndex];
    [oneHundredDudes removeObjectAtIndex:0];
    [oneHundredDudes insertObject:willMoveToHeadDude atIndex:0];
    [oneHundredDudes insertObject:willMoveDownDude atIndex:willMoveDownToIndex];
    
    // Refresh
    [data refresh];
    
    
    // Make sure the dudes are both in data and the top dude is at the top
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        BOOL topDudeCorrect = [[data.contacts firstObject] isEqualToContact:willMoveToHeadDude];
        BOOL dudeMovedDown = ([data.contacts indexOfObject:willMoveDownDude] == willMoveDownToIndex);
        return topDudeCorrect && dudeMovedDown;
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testOneDudeGoneOneNewDudeAtTail
{
    NSUInteger pageSize = 100;
    NSArray<ZNGContact *> * oneHundredDudes = [self oneHundredDudes];
    NSMutableArray<ZNGContact *> * fiftyDudes = [[oneHundredDudes subarrayWithRange:NSMakeRange(0, 50)] mutableCopy];
    ZNGContact * newDude = oneHundredDudes[75];
    
    // Pick someone in the rough middle of a page
    NSUInteger oldDude1Index = 27;
    ZNGContact * oldDude1 = fiftyDudes[oldDude1Index];
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = fiftyDudes;
    ZNGInboxDataSet * data = [ZNGInboxDataSet dataSetWithBlock:^(ZNGContactDataSetBuilder * _Nonnull builder) {
        builder.contactClient = contactClient;
        builder.pageSize = pageSize;
    }];

    [data refresh];
    
    
    // Is he there?
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return ([data.contacts containsObject:oldDude1] && ![data.contacts containsObject:newDude]);
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    
    // Remove the old dude and add the new dude
    [fiftyDudes removeObjectAtIndex:oldDude1Index];
    [fiftyDudes addObject:newDude];
    
    // Refresh
    [data refresh];
    
    
    // Make sure only the new dude is around
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return ([data.contacts containsObject:newDude] && ![data.contacts containsObject:oldDude1]);
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testTwoDudesGoneOneNewDudeAtTail
{
    NSUInteger pageSize = 100;
    NSArray<ZNGContact *> * oneHundredDudes = [self oneHundredDudes];
    NSMutableArray<ZNGContact *> * fiftyDudes = [[oneHundredDudes subarrayWithRange:NSMakeRange(0, 50)] mutableCopy];
    ZNGContact * newDude = oneHundredDudes[75];
    
    // Pick someone in the rough middle of a page
    NSUInteger oldDude1Index = 27;
    ZNGContact * oldDude1 = fiftyDudes[oldDude1Index];
    NSUInteger oldDude2Index = 42;
    ZNGContact * oldDude2 = fiftyDudes[oldDude2Index];
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = fiftyDudes;
    
    ZNGInboxDataSet * data = [ZNGInboxDataSet dataSetWithBlock:^(ZNGContactDataSetBuilder * _Nonnull builder) {
        builder.contactClient = contactClient;
        builder.pageSize = pageSize;
    }];

    [data refresh];
    
    
    // Is he there?
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return ([data.contacts containsObject:oldDude1] && [data.contacts containsObject:oldDude2] && ![data.contacts containsObject:newDude]);
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    
    // Remove the old dude and add the new dude
    [fiftyDudes removeObjectAtIndex:oldDude1Index];
    [fiftyDudes removeObject:oldDude2];
    [fiftyDudes addObject:newDude];
    
    // Refresh
    [data refresh];
    
    
    // Make sure only the new dude is around
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        return ([data.contacts containsObject:newDude] && ![data.contacts containsObject:oldDude1] && ![data.contacts containsObject:oldDude2]);
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void) testFiveNewDudesAtHeadFiveNewAtTail
{
    NSUInteger pageSize = 100;
    NSArray<ZNGContact *> * oneHundredDudes = [self oneHundredDudes];
    NSMutableArray<ZNGContact *> * fiftyDudes = [[oneHundredDudes subarrayWithRange:NSMakeRange(0, 50)] mutableCopy];
    NSArray<ZNGContact *> * fiveNewHeadDudes = [oneHundredDudes subarrayWithRange:NSMakeRange(50, 5)];
    NSArray<ZNGContact *> * fiveNewTailDudes = [oneHundredDudes subarrayWithRange:NSMakeRange(55, 5)];
    
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    contactClient.contacts = fiftyDudes;
    
    ZNGInboxDataSet * data = [ZNGInboxDataSet dataSetWithBlock:^(ZNGContactDataSetBuilder * _Nonnull builder) {
        builder.contactClient = contactClient;
        builder.pageSize = pageSize;
    }];

    [data refresh];
    
    
    // Wait for all original fifty dudes to arrive.  Ensure new dudes are not there.
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        if ([data.contacts count] != 50) {
            return NO;
        }
        
        NSArray<ZNGContact *> * tooEarlyDudes = [fiveNewHeadDudes arrayByAddingObjectsFromArray:fiveNewTailDudes];
        for (ZNGContact * dude in tooEarlyDudes) {
            if ([data.contacts containsObject:dude]) {
                return NO;
            }
        }
        
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    
    // Add the new dudes
    [fiftyDudes insertObjects:fiveNewHeadDudes atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 5)]];
    [fiftyDudes addObjectsFromArray:fiveNewTailDudes];
    
    // Refresh
    [data refresh];
    
    
    // Find the new dudes
    [self keyValueObservingExpectationForObject:data keyPath:@"contacts" handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        NSArray<ZNGContact *> * newDudes = [fiveNewHeadDudes arrayByAddingObjectsFromArray:fiveNewTailDudes];
        
        for (ZNGContact * dude in newDudes) {
            if (![data.contacts containsObject:dude]) {
                return NO;
            }
        }
        
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
