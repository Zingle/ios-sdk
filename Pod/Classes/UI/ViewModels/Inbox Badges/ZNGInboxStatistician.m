//
//  ZNGInboxStatistician.m
//  ZingleSDK
//
//  Created by Jason Neel on 1/23/18.
//

#import "ZNGInboxStatistician.h"
#import "ZNGTeamV2.h"
#import "ZNGUser.h"
#import "ZNGInboxStatsEntry.h"

@import SBObjectiveCWrapper;

NSString * const ZNGInboxStatisticianDataChangedNotification = @"ZNGInboxStatisticianDataChangedNotification";


@implementation ZNGInboxStatistician
{
    NSMutableDictionary <NSString *, NSNumber *> * teamNumericIdsByUuid;
    
    ZNGInboxStatsEntry * unassignedStatsEntry;
    NSMutableDictionary<NSNumber *, ZNGInboxStatsEntry *> * teamStats;
    NSMutableDictionary<NSNumber *, ZNGInboxStatsEntry *> * userStats;
}

- (id) init
{
    self = [super init];
    
    if (self != nil) {
        teamNumericIdsByUuid = [[NSMutableDictionary alloc] init];
        teamStats = [[NSMutableDictionary alloc] init];
        userStats = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

#pragma mark - Writing
- (void) updateWithSocketData:(NSArray<NSDictionary *> *)socketData
{
    SBLogVerbose(@"Updating inbox stats with socket data: %@", socketData);
    
    // Record old values to determine if things have changed
    ZNGInboxStatsEntry * oldUnassignedStats = unassignedStatsEntry;
    NSDictionary * oldTeamsStats = [teamStats copy];
    NSDictionary * oldUserStats = [userStats copy];
        
    NSDictionary * data = [socketData firstObject];
    
    if (![data isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSDictionary * teams = data[@"teams"];
    NSDictionary * unassigned = data[@"unassigned"];
    NSDictionary * users = data[@"users"];
    
    if ([unassigned isKindOfClass:[NSDictionary class]]) {
        unassignedStatsEntry = [MTLJSONAdapter modelOfClass:[ZNGInboxStatsEntry class] fromJSONDictionary:unassigned error:nil];
    } else {
        unassignedStatsEntry = nil;
    }
    
    if ([teams isKindOfClass:[NSDictionary class]]) {
        [teams enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull teamId, NSDictionary * _Nonnull teamData, BOOL * _Nonnull stop) {
            self->teamStats[@([teamId intValue])] = [MTLJSONAdapter modelOfClass:[ZNGInboxStatsEntry class] fromJSONDictionary:teamData error:nil];;
        }];
        
        // Remove any unincluded teams
        for (NSNumber * teamId in [[teamStats allKeys] copy]) {
            if (teams[[teamId stringValue]] == nil) {
                [teamStats removeObjectForKey:teamId];
            }
        }
    } else {
        // No teams data at all.  Delete it all.
        [teamStats removeAllObjects];
    }
    
    if ([users isKindOfClass:[NSDictionary class]]) {
        [users enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull userId, NSDictionary * _Nonnull userData, BOOL * _Nonnull stop) {
            self->userStats[@([userId intValue])] = [MTLJSONAdapter modelOfClass:[ZNGInboxStatsEntry class] fromJSONDictionary:userData error:nil];
        }];
        
        // Remove any unincluded users
        for (NSNumber * userId in [[userStats allKeys] copy]) {
            if (users[[userId stringValue]] == nil) {
                [userStats removeObjectForKey:userId];
            }
        }
    } else {
        // No users data at all.  Delete it.
        [userStats removeAllObjects];
    }
    
    // Check for changes and send a notification if any exist
    if ((![unassignedStatsEntry isEqual:oldUnassignedStats]) || (![teamStats isEqualToDictionary:oldTeamsStats]) || (![userStats isEqualToDictionary:oldUserStats])) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNGInboxStatisticianDataChangedNotification object:self];
    }
}

- (void) updateWithV2TeamsData:(NSArray<ZNGTeamV2 *> *)teams
{
    for (ZNGTeamV2 * team in teams) {
        if (([team.teamId length] > 0) && (team.numericId > 0)) {
            teamNumericIdsByUuid[team.teamId] = @(team.numericId);
        }
    }
}

#pragma mark - Reading
- (ZNGInboxStatsEntry *) statsForUnassigned
{
    return unassignedStatsEntry;
}

- (ZNGInboxStatsEntry *) statsForTeam:(ZNGTeam *)team
{
    if ([team.teamId length] == 0) {
        SBLogWarning(@"%s called with a team with no UUID.  Returning 0.", __PRETTY_FUNCTION__);
        return nil;
    }
    
    NSNumber * teamId = teamNumericIdsByUuid[team.teamId];
    
    if (teamId == nil) {
        return nil;
    }
    
    return teamStats[teamId];
}

- (ZNGInboxStatsEntry *) statsForUser:(ZNGUser *)user
{
    return userStats[@(user.numericId)];
}

- (ZNGInboxStatsEntry * _Nullable) combinedStatsForAll
{
    NSMutableArray<ZNGInboxStatsEntry *> * stats = [[NSMutableArray alloc] initWithCapacity:[userStats count] + [teamStats count] + 1];
    
    ZNGInboxStatsEntry * unassigned = [self statsForUnassigned];
    
    if (unassigned != nil) {
        [stats addObject:unassigned];
    }
    
    [stats addObjectsFromArray:[teamStats allValues]];
    [stats addObjectsFromArray:[userStats allValues]];
    
    return [[ZNGInboxStatsEntry alloc] initByCombiningEntries:stats];
}

- (ZNGInboxStatsEntry * _Nullable) combinedStatsForUser:(ZNGUser *)user teams:(NSArray<ZNGTeam *> *)teams includeUnassigned:(BOOL)includeUnassigned
{
    NSMutableArray<ZNGInboxStatsEntry *> * stats = [[NSMutableArray alloc] initWithCapacity:[teams count] + 2];
    
    for (ZNGTeam * team in teams) {
        ZNGInboxStatsEntry * teamStats = [self statsForTeam:team];
        
        if (teamStats != nil) {
            [stats addObject:teamStats];
        }
    }
    
    if (includeUnassigned) {
        ZNGInboxStatsEntry * unassignedStats = [self statsForUnassigned];
        
        if (unassignedStats != nil) {
            [stats addObject:unassignedStats];
        }
    }
    
    ZNGInboxStatsEntry * userStats = [self statsForUser:user];
    
    if (userStats != nil) {
        [stats addObject:userStats];
    }
    
    return [[ZNGInboxStatsEntry alloc] initByCombiningEntries:stats];
}

@end
