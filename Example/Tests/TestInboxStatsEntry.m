//
//  TestInboxStatsEntry.m
//  Tests
//
//  Created by Jason Neel on 1/24/18.
//  Copyright © 2018 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZingleSDK/ZNGInboxStatsEntry.h"

@interface TestInboxStatsEntry : XCTestCase

@end

@implementation TestInboxStatsEntry

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testOpenCountCombined
{    ZNGInboxStatsEntry * entry1 = [[ZNGInboxStatsEntry alloc] init];
    entry1.openCount = 1;
    
    ZNGInboxStatsEntry * entry2 = [[ZNGInboxStatsEntry alloc] init];
    entry2.openCount = 2;
    
    ZNGInboxStatsEntry * entry3 = [[ZNGInboxStatsEntry alloc] init];
    entry3.openCount = 3;
    
    ZNGInboxStatsEntry * combined = [[ZNGInboxStatsEntry alloc] initByCombiningEntries:@[entry1, entry2, entry3]];
    
    XCTAssert(combined.openCount = (entry1.openCount + entry2.openCount + entry3.openCount));
}

- (void) testUnreadCountCombined
{
    ZNGInboxStatsEntry * entry1 = [[ZNGInboxStatsEntry alloc] init];
    entry1.unreadCount = 1;
    
    ZNGInboxStatsEntry * entry2 = [[ZNGInboxStatsEntry alloc] init];
    entry2.unreadCount = 2;
    
    ZNGInboxStatsEntry * entry3 = [[ZNGInboxStatsEntry alloc] init];
    entry3.unreadCount = 3;
    
    ZNGInboxStatsEntry * combined = [[ZNGInboxStatsEntry alloc] initByCombiningEntries:@[entry1, entry2, entry3]];
    
    XCTAssert(combined.unreadCount = (entry1.unreadCount + entry2.unreadCount + entry3.unreadCount));
}

- (void) testSingleDateUsedAsOldest
{
    NSDate * bestDay = [NSDate dateWithTimeIntervalSince1970:484354364.0];
    
    ZNGInboxStatsEntry * entryWithDate = [[ZNGInboxStatsEntry alloc] init];
    entryWithDate.oldestUnconfirmed = bestDay;
    
    ZNGInboxStatsEntry * entryWithoutDate = [[ZNGInboxStatsEntry alloc] init];
    
    ZNGInboxStatsEntry * combined = [[ZNGInboxStatsEntry alloc] initByCombiningEntries:@[entryWithDate, entryWithoutDate]];
    
    XCTAssertEqual(combined.oldestUnconfirmed, entryWithDate.oldestUnconfirmed);
}

- (void) testOldestOfMultipleDatesPreserved
{
    NSDate * bestDay = [NSDate dateWithTimeIntervalSince1970:484354364.0];
    NSDate * moreRecentDate = [bestDay dateByAddingTimeInterval:3600.0];
    
    ZNGInboxStatsEntry * entryWithOldDate = [[ZNGInboxStatsEntry alloc] init];
    entryWithOldDate.oldestUnconfirmed = bestDay;
    
    ZNGInboxStatsEntry * entryWithMoreRecentDate = [[ZNGInboxStatsEntry alloc] init];
    entryWithMoreRecentDate.oldestUnconfirmed = moreRecentDate;
    
    ZNGInboxStatsEntry * combined = [[ZNGInboxStatsEntry alloc] initByCombiningEntries:@[entryWithOldDate, entryWithMoreRecentDate]];
    XCTAssertEqual(combined.oldestUnconfirmed, entryWithOldDate.oldestUnconfirmed);
    
    // Test the reverse order
    combined = [[ZNGInboxStatsEntry alloc] initByCombiningEntries:@[entryWithMoreRecentDate, entryWithOldDate]];
    XCTAssertEqual(combined.oldestUnconfirmed, entryWithOldDate.oldestUnconfirmed);
}

@end
