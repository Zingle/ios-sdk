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

static const int zngLogLevel = ZNGLogLevelInfo;

@implementation ZNGInboxStatistician
{
    NSMutableDictionary <NSString *, NSNumber *> * teamNumericIdsByUuid;
    
    NSUInteger unassignedOpenCount;
    NSMutableDictionary <NSNumber *, NSNumber *> * teamOpenCounts;  // Keyed by numeric ID not UUID
    NSMutableDictionary <NSNumber *, NSNumber *> * userOpenCounts;  // Keyed by numeric ID not UUID
}

- (id) init
{
    self = [super init];
    
    if (self != nil) {
        teamNumericIdsByUuid = [[NSMutableDictionary alloc] init];
        teamOpenCounts = [[NSMutableDictionary alloc] init];
        userOpenCounts = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

#pragma mark - Writing
- (void) updateWithSocketData:(NSArray<NSDictionary *> *)socketData
{
    NSDictionary * data = [socketData firstObject];
    
    NSDictionary<NSString *, NSDictionary *> * teams = data[@"teams"];
    NSDictionary<NSString *, id> * unassigned = data[@"unassigned"];
    NSDictionary<NSString *, NSDictionary *> * users = data[@"users"];
    
    if (([unassigned isKindOfClass:[NSDictionary class]]) && ([unassigned[@"open"] isKindOfClass:[NSNumber class]])) {
        unassignedOpenCount = [unassigned[@"open"] unsignedIntegerValue];
    }
    
    if ([teams isKindOfClass:[NSDictionary class]]) {
        [teams enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull teamId, NSDictionary * _Nonnull teamData, BOOL * _Nonnull stop) {
            teamOpenCounts[@([teamId intValue])] = @([teamData[@"open"] unsignedIntegerValue]);
        }];
    }
    
    if ([users isKindOfClass:[NSDictionary class]]) {
        [users enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull userId, NSDictionary * _Nonnull userData, BOOL * _Nonnull stop) {
            userOpenCounts[@([userId intValue])] = @([userData[@"open"] unsignedIntegerValue]);
        }];
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
- (NSUInteger) openCountForTeam:(ZNGTeam *)team
{
    if ([team.teamId length] == 0) {
        ZNGLogWarn(@"%s called with a team with no UUID.  Returning 0.", __PRETTY_FUNCTION__);
        return 0;
    }
    
    NSNumber * teamId = teamNumericIdsByUuid[team.teamId];
    
    if (teamId == nil) {
        return 0;
    }
    
    return [teamOpenCounts[teamId] unsignedIntegerValue];
}

- (NSUInteger) openCountForUser:(ZNGUser *)user
{
    return [userOpenCounts[@(user.numericId)] unsignedIntegerValue];
}

- (NSUInteger) unassignedOpenCount
{
    return unassignedOpenCount;
}

@end
