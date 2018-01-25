//
//  ZNGInboxStatistician.m
//  ZingleSDK
//
//  Created by Jason Neel on 1/23/18.
//

#import "ZNGInboxStatistician.h"
#import "ZNGTeamV2.h"
#import "ZNGLogging.h"
#import "ZNGUser.h"
#import "ZNGInboxStatsEntry.h"

static const int zngLogLevel = ZNGLogLevelInfo;

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
    ZNGLogVerbose(@"Updating inbox stats with socket data: %@", socketData);
    
    NSDictionary * data = [socketData firstObject];
    
    if (![data isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSDictionary * teams = data[@"teams"];
    NSDictionary * unassigned = data[@"unassigned"];
    NSDictionary * users = data[@"users"];
    
    if ([unassigned isKindOfClass:[NSDictionary class]]) {
        unassignedStatsEntry = [MTLJSONAdapter modelOfClass:[ZNGInboxStatsEntry class] fromJSONDictionary:unassigned error:nil];
    }
    
    if ([teams isKindOfClass:[NSDictionary class]]) {
        [teams enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull teamId, NSDictionary * _Nonnull teamData, BOOL * _Nonnull stop) {
            teamStats[@([teamId intValue])] = [MTLJSONAdapter modelOfClass:[ZNGInboxStatsEntry class] fromJSONDictionary:teamData error:nil];;
        }];
    }
    
    if ([users isKindOfClass:[NSDictionary class]]) {
        [users enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull userId, NSDictionary * _Nonnull userData, BOOL * _Nonnull stop) {
            userStats[@([userId intValue])] = [MTLJSONAdapter modelOfClass:[ZNGInboxStatsEntry class] fromJSONDictionary:userData error:nil];
        }];
    }
    
    // TODO: Check if any data has changed and post a notification if so.
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
        ZNGLogWarn(@"%s called with a team with no UUID.  Returning 0.", __PRETTY_FUNCTION__);
        return 0;
    }
    
    NSNumber * teamId = teamNumericIdsByUuid[team.teamId];
    
    if (teamId == nil) {
        return 0;
    }
    
    return teamStats[teamId];
}

- (ZNGInboxStatsEntry *) statsForUser:(ZNGUser *)user
{
    return userStats[@(user.numericId)];
}

- (ZNGInboxStatsEntry * _Nullable) combinedStatsForUnassignedAndUser:(ZNGUser *)user andTeams:(NSArray<ZNGTeam *> *)teams
{
    NSMutableArray<ZNGInboxStatsEntry *> * stats = [[NSMutableArray alloc] initWithCapacity:[teams count] + 2];
    
    for (ZNGTeam * team in teams) {
        [stats addObject:[self statsForTeam:team]];
    }
    
    [stats addObject:[self statsForUnassigned]];
    [stats addObject:[self statsForUser:user]];
    
    return [[ZNGInboxStatsEntry alloc] initByCombiningEntries:stats];
}

@end
