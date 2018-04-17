//
//  ZNGInboxStatistician.h
//  ZingleSDK
//
//  Created by Jason Neel on 1/23/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const ZNGInboxStatisticianDataChangedNotification;

@class ZNGInboxStatsEntry;
@class ZNGTeam;
@class ZNGTeamV2;
@class ZNGUser;

@interface ZNGInboxStatistician : NSObject

#pragma mark - Writing
- (void) updateWithSocketData:(NSArray<NSDictionary *> *)socketData;

/**
 *  Necessary to associate UUIDs with numeric IDs.
 */
- (void) updateWithV2TeamsData:(NSArray<ZNGTeamV2 *> *)teams;

#pragma mark - Reading
- (ZNGInboxStatsEntry * _Nullable) combinedStatsForAll;
- (ZNGInboxStatsEntry * _Nullable) statsForUnassigned;
- (ZNGInboxStatsEntry * _Nullable) statsForTeam:(ZNGTeam *)team;
- (ZNGInboxStatsEntry * _Nullable) statsForUser:(ZNGUser *)user;
- (ZNGInboxStatsEntry * _Nullable) combinedStatsForUser:(ZNGUser * _Nullable)user teams:(NSArray<ZNGTeam *> * _Nullable)teams includeUnassigned:(BOOL)includeUnassigned;

@end

NS_ASSUME_NONNULL_END
