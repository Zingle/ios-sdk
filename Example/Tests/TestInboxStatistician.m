//
//  TestInboxStatistician.m
//  Tests
//
//  Created by Jason Neel on 3/20/18.
//  Copyright © 2018 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZingleSDK/ZNGInboxStatistician.h"
#import "ZingleSDK/ZNGInboxStatsEntry.h"
#import "ZingleSDK/ZNGTeamV2.h"
#import "ZingleSDK/ZNGUser.h"

@interface TestInboxStatistician : XCTestCase

@end

@implementation TestInboxStatistician

#pragma mark - Data
- (ZNGTeamV2 *) team
{
    ZNGTeamV2 * team = [[ZNGTeamV2 alloc] init];
    team.teamId = @"12341234-1234123412341-12341234";
    team.displayName = @"Some Team";
    team.numericId = 5;
    
    return team;
}

- (ZNGUser *) user
{
    ZNGUser * user = [[ZNGUser alloc] init];
    user.userId = @"abcdabcdabcdabcd-12341234-abcdabcdabcdabcd";
    user.firstName = @"Dude";
    user.lastName = @"Personson";
    user.username = @"dude.personson@fake.mail";
    user.email = user.username;
    user.numericId = 69;
    
    return user;
}

- (NSArray<NSDictionary *> *) socketDataWithZeroEverythingData
{
    ZNGUser * user = [self user];
    ZNGTeamV2 * team = [self team];
    ZNGInboxStatsEntry * zeroStats = [[ZNGInboxStatsEntry alloc] init];
    NSDictionary * zeroStatsDictionary = [MTLJSONAdapter JSONDictionaryFromModel:zeroStats error:nil];

    return @[@{
                 @"unassigned": zeroStatsDictionary,
                 @"teams": @{
                         @(team.numericId): zeroStatsDictionary,
                         },
                 @"users": @{
                         @(user.numericId): zeroStatsDictionary,
                         },
                 }];
}

- (NSArray<NSDictionary *> *) socketDataWithNonZeroUnassigned
{
    ZNGInboxStatsEntry * nonZeroStats = [[ZNGInboxStatsEntry alloc] init];
    nonZeroStats.unreadCount = 1;
    nonZeroStats.openCount = 1;
    nonZeroStats.oldestUnconfirmed = [NSDate dateWithTimeIntervalSince1970:1494115200.0];
    NSDictionary * nonZeroDictionary = [MTLJSONAdapter JSONDictionaryFromModel:nonZeroStats error:nil];
    
    return @[@{
                 @"unassigned": nonZeroDictionary,
                 }];
}

- (NSArray<NSDictionary *> *) socketDataWithZeroRelevantDataButSomeRandomTeamAndUserData
{
    ZNGInboxStatsEntry * nonZeroUser = [[ZNGInboxStatsEntry alloc] init];
    nonZeroUser.unreadCount = 1;
    nonZeroUser.openCount = 1;
    nonZeroUser.oldestUnconfirmed = [NSDate dateWithTimeIntervalSince1970:1494115200.0];
    NSDictionary * nonZeroUserDictionary = [MTLJSONAdapter JSONDictionaryFromModel:nonZeroUser error:nil];
    
    ZNGInboxStatsEntry * nonZeroTeam = [[ZNGInboxStatsEntry alloc] init];
    nonZeroTeam.unreadCount = 2;
    nonZeroTeam.openCount = 2;
    nonZeroTeam.oldestUnconfirmed = [NSDate dateWithTimeIntervalSince1970:1462579200.0];
    NSDictionary * nonZeroTeamDictionary = [MTLJSONAdapter JSONDictionaryFromModel:nonZeroTeam error:nil];
    
    return @[@{
                 @"teams": @{
                         @12345: nonZeroTeamDictionary,
                         },
                 @"users": @{
                         @5678: nonZeroUserDictionary,
                         },
                 }];
}

- (NSArray<NSDictionary *> *) socketDataWithZeroUnassignedAndNonZeroTeamAndUser
{
    ZNGUser * user = [self user];
    ZNGTeamV2 * team = [self team];
    ZNGInboxStatsEntry * zeroUnassigned = [[ZNGInboxStatsEntry alloc] init];
    NSDictionary * zeroUnassignedDictionary = [MTLJSONAdapter JSONDictionaryFromModel:zeroUnassigned error:nil];
    
    ZNGInboxStatsEntry * nonZeroUser = [[ZNGInboxStatsEntry alloc] init];
    nonZeroUser.unreadCount = 1;
    nonZeroUser.openCount = 1;
    nonZeroUser.oldestUnconfirmed = [NSDate dateWithTimeIntervalSince1970:1494115200.0];
    NSDictionary * nonZeroUserDictionary = [MTLJSONAdapter JSONDictionaryFromModel:nonZeroUser error:nil];
    
    ZNGInboxStatsEntry * nonZeroTeam = [[ZNGInboxStatsEntry alloc] init];
    nonZeroTeam.unreadCount = 2;
    nonZeroTeam.openCount = 2;
    nonZeroTeam.oldestUnconfirmed = [NSDate dateWithTimeIntervalSince1970:1462579200.0];
    NSDictionary * nonZeroTeamDictionary = [MTLJSONAdapter JSONDictionaryFromModel:nonZeroTeam error:nil];
    
    return @[@{
             @"unassigned": zeroUnassignedDictionary,
             @"teams": @{
                     @(team.numericId): nonZeroTeamDictionary,
                     },
             @"users": @{
                     @(user.numericId): nonZeroUserDictionary,
                     },
             }];
}

#pragma mark - Empty data tests
- (void) testEmptyDataShowsNoUnassigned
{
    ZNGInboxStatistician * emptyStats = [[ZNGInboxStatistician alloc] init];
    ZNGInboxStatsEntry * unassignedStats = [emptyStats statsForUnassigned];
    
    XCTAssertEqual(unassignedStats.unreadCount, 0, @"Unassigned unread count should be 0 when no data is present.");
    XCTAssertEqual(unassignedStats.openCount, 0, @"Unassigned open count should be 0 when no data is present.");
    XCTAssertNil(unassignedStats.oldestUnconfirmed, @"Unassigned oldest unconfirmed timestamp should be nil when no data is present.");
}

- (void) testEmptyDataShowsNoDataForTeam
{
    ZNGInboxStatistician * stats = [[ZNGInboxStatistician alloc] init];
    ZNGTeam * team = [self team];
    ZNGInboxStatsEntry * teamStats = [stats statsForTeam:team];
    
    XCTAssertEqual(teamStats.unreadCount, 0, @"Unread count for a team should be 0 when no data is present.");
    XCTAssertEqual(teamStats.openCount, 0, @"Open count for a team should be 0 when no data is present.");
    XCTAssertNil(teamStats.oldestUnconfirmed, @"Oldest unconfirmed timestamp for a team should be nil when no data is present.");
}

- (void) testEmptyDataShowsNoDataForUser
{
    ZNGInboxStatistician * stats = [[ZNGInboxStatistician alloc] init];
    ZNGUser * dude = [self user];
    ZNGInboxStatsEntry * userStats = [stats statsForUser:dude];
    
    XCTAssertEqual(userStats.unreadCount, 0, @"Unread count for a user should be 0 when no data is present.");
    XCTAssertEqual(userStats.openCount, 0, @"Open count for a user should be 0 when no data is present.");
    XCTAssertNil(userStats.oldestUnconfirmed, @"Oldest unconfirmed timestamp for a user should be nil when no data is present.");
}

#pragma mark - Non empty data tests
- (void) testZeroUnassignedData
{
    ZNGInboxStatistician * stats = [[ZNGInboxStatistician alloc] init];
    [stats updateWithSocketData:[self socketDataWithZeroUnassignedAndNonZeroTeamAndUser]];
    
    ZNGInboxStatsEntry * unassignedStats = [stats statsForUnassigned];
    XCTAssertEqual(unassignedStats.openCount, 0);
    XCTAssertEqual(unassignedStats.unreadCount, 0);
    XCTAssertNil(unassignedStats.oldestUnconfirmed);
}

- (void) testNonZeroTeamData
{
    ZNGInboxStatistician * stats = [[ZNGInboxStatistician alloc] init];
    ZNGTeamV2 * team = [self team];
    [stats updateWithV2TeamsData:@[team]];
    [stats updateWithSocketData:[self socketDataWithZeroUnassignedAndNonZeroTeamAndUser]];
    
    ZNGInboxStatsEntry * teamStats = [stats statsForTeam:team];
    XCTAssertNotEqual(teamStats.unreadCount, 0);
    XCTAssertNotEqual(teamStats.openCount, 0);
    XCTAssertNotNil(teamStats.oldestUnconfirmed);
}

- (void) testNonZeroUserData
{
    ZNGInboxStatistician * stats = [[ZNGInboxStatistician alloc] init];
    ZNGUser * dude = [self user];
    [stats updateWithSocketData:[self socketDataWithZeroUnassignedAndNonZeroTeamAndUser]];
    
    ZNGInboxStatsEntry * dudeStats = [stats statsForUser:dude];
    XCTAssertNotEqual(dudeStats.unreadCount, 0);
    XCTAssertNotEqual(dudeStats.openCount, 0);
    XCTAssertNotNil(dudeStats.oldestUnconfirmed);
}

#pragma mark - Changing data tests
// An empty update should set all counts/badges to 0
- (void) testEmptyUpdateClearsUnassigned
{
    ZNGInboxStatistician * stats = [[ZNGInboxStatistician alloc] init];
    [stats updateWithSocketData:[self socketDataWithNonZeroUnassigned]];
    
    // Verify we're non zero
    ZNGInboxStatsEntry * unassignedStats = [stats statsForUnassigned];
    XCTAssertNotEqual(unassignedStats.unreadCount, 0);
    XCTAssertNotEqual(unassignedStats.openCount, 0);
    XCTAssertNotNil(unassignedStats.oldestUnconfirmed);
    
    // Send empty data to clear everything
    [stats updateWithSocketData:@[@{}]];
    
    // No we should be zero
    unassignedStats = [stats statsForUnassigned];
    XCTAssertEqual(unassignedStats.unreadCount, 0);
    XCTAssertEqual(unassignedStats.openCount, 0);
    XCTAssertNil(unassignedStats.oldestUnconfirmed);
}

- (void) testUserDataFromZeroToNonZero
{
    ZNGInboxStatistician * stats = [[ZNGInboxStatistician alloc] init];
    ZNGUser * dude = [self user];
    [stats updateWithSocketData:[self socketDataWithZeroEverythingData]];

    // First verify that everything is 0/nil
    ZNGInboxStatsEntry * dudeStats = [stats statsForUser:dude];
    XCTAssertEqual(dudeStats.openCount, 0);
    XCTAssertEqual(dudeStats.unreadCount, 0);
    XCTAssertNil(dudeStats.oldestUnconfirmed);
    
    // Update stats with non zero data
    [stats updateWithSocketData:[self socketDataWithZeroUnassignedAndNonZeroTeamAndUser]];
    
    // Verify non zero stats
    dudeStats = [stats statsForUser:dude];
    XCTAssertNotEqual(dudeStats.openCount, 0);
    XCTAssertNotEqual(dudeStats.unreadCount, 0);
    XCTAssertNotNil(dudeStats.oldestUnconfirmed);
}

// Opposite of above test
- (void) testUserDataFromNonZeroToZero
{
    ZNGInboxStatistician * stats = [[ZNGInboxStatistician alloc] init];
    ZNGUser * dude = [self user];
    [stats updateWithSocketData:[self socketDataWithZeroUnassignedAndNonZeroTeamAndUser]];
    
    // First verify that everything is non zero
    ZNGInboxStatsEntry * dudeStats = [stats statsForUser:dude];
    XCTAssertNotEqual(dudeStats.openCount, 0);
    XCTAssertNotEqual(dudeStats.unreadCount, 0);
    XCTAssertNotNil(dudeStats.oldestUnconfirmed);
    
    // Update stats with zeroed data
    [stats updateWithSocketData:[self socketDataWithZeroEverythingData]];
    
    // Verify zero stats
    dudeStats = [stats statsForUser:dude];
    XCTAssertEqual(dudeStats.openCount, 0);
    XCTAssertEqual(dudeStats.unreadCount, 0);
    XCTAssertNil(dudeStats.oldestUnconfirmed);
}

// Verify that a badgeData update from socket that neglects a team/user indicates that the data for that user should be 0/nil
- (void) testOmittedUserDataAssumedZero
{
    ZNGInboxStatistician * stats = [[ZNGInboxStatistician alloc] init];
    ZNGUser * dude = [self user];
    [stats updateWithSocketData:[self socketDataWithZeroUnassignedAndNonZeroTeamAndUser]];
    
    // Ensure we start with non zero
    ZNGInboxStatsEntry * dudeStats = [stats statsForUser:dude];
    XCTAssertNotEqual(dudeStats.openCount, 0);
    XCTAssertNotEqual(dudeStats.unreadCount, 0);
    XCTAssertNotNil(dudeStats.oldestUnconfirmed);
    
    // Send an empty update
    [stats updateWithSocketData:@[@{}]];
    
    // All user data should now be 0/nil
    dudeStats = [stats statsForUser:dude];
    XCTAssertEqual(dudeStats.openCount, 0);
    XCTAssertEqual(dudeStats.unreadCount, 0);
    XCTAssertNil(dudeStats.oldestUnconfirmed);
}

// Same as above test but for teams
- (void) testOmittedTeamDataAssumedZero
{
    ZNGInboxStatistician * stats = [[ZNGInboxStatistician alloc] init];
    ZNGTeamV2 * team = [self team];
    [stats updateWithV2TeamsData:@[team]];
    [stats updateWithSocketData:[self socketDataWithZeroUnassignedAndNonZeroTeamAndUser]];
    
    // Ensure we start with non zero
    ZNGInboxStatsEntry * teamStats = [stats statsForTeam:team];
    XCTAssertNotEqual(teamStats.openCount, 0);
    XCTAssertNotEqual(teamStats.unreadCount, 0);
    XCTAssertNotNil(teamStats.oldestUnconfirmed);
    
    // Send an empty update
    [stats updateWithSocketData:@[@{}]];
    
    // All team data should now be 0/nil
    teamStats = [stats statsForTeam:team];
    XCTAssertEqual(teamStats.openCount, 0);
    XCTAssertEqual(teamStats.unreadCount, 0);
    XCTAssertNil(teamStats.oldestUnconfirmed);
}

/**
 *  Badge data should always be complete.  Verify that missing data is assumed zero.
 */
- (void) testDataWithOnlyIrrelevantTeamsErasesPreviousTeamsData
{
    ZNGInboxStatistician * stats = [[ZNGInboxStatistician alloc] init];
    ZNGTeamV2 * team = [self team];
    [stats updateWithV2TeamsData:@[team]];
    [stats updateWithSocketData:[self socketDataWithZeroUnassignedAndNonZeroTeamAndUser]];
    
    // Ensure we start with non zero
    ZNGInboxStatsEntry * teamStats = [stats statsForTeam:team];
    XCTAssertNotEqual(teamStats.openCount, 0);
    XCTAssertNotEqual(teamStats.unreadCount, 0);
    XCTAssertNotNil(teamStats.oldestUnconfirmed);
    
    // Update the statistician with data for some other teams/users with nothing for the current team
    [stats updateWithSocketData:[self socketDataWithZeroRelevantDataButSomeRandomTeamAndUserData]];
    
    // Data for our team should now be 0/nil
    teamStats = [stats statsForTeam:team];
    XCTAssertEqual(teamStats.openCount, 0);
    XCTAssertEqual(teamStats.unreadCount, 0);
    XCTAssertNil(teamStats.oldestUnconfirmed);
}

// Same as above test but for user
- (void) testDataWithOnlyIrrelevantUsersErasesPreviousUsersData
{
    ZNGInboxStatistician * stats = [[ZNGInboxStatistician alloc] init];
    ZNGUser * dude = [self user];
    [stats updateWithSocketData:[self socketDataWithZeroUnassignedAndNonZeroTeamAndUser]];
    
    // Ensure we start with non zero
    ZNGInboxStatsEntry * dudeStats = [stats statsForUser:dude];
    XCTAssertNotEqual(dudeStats.openCount, 0);
    XCTAssertNotEqual(dudeStats.unreadCount, 0);
    XCTAssertNotNil(dudeStats.oldestUnconfirmed);
    
    // Update the statistician with data for some other teams/users with nothing for the current user
    [stats updateWithSocketData:[self socketDataWithZeroRelevantDataButSomeRandomTeamAndUserData]];
    
    // Data for our user should now be 0/nil
    dudeStats = [stats statsForUser:dude];
    XCTAssertEqual(dudeStats.openCount, 0);
    XCTAssertEqual(dudeStats.unreadCount, 0);
    XCTAssertNil(dudeStats.oldestUnconfirmed);
}

@end
