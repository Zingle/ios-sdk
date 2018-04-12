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

#pragma mark - Reading
- (ZNGInboxStatsEntry * _Nullable) statsForUnassigned;
- (ZNGInboxStatsEntry * _Nullable) statsForTeam:(ZNGTeam *)team;
- (ZNGInboxStatsEntry * _Nullable) statsForUser:(ZNGUser *)user;
- (ZNGInboxStatsEntry * _Nullable) combinedStatsForUnassignedAndUser:(ZNGUser *)user andTeams:(NSArray<ZNGTeam *> *)teams;

@end

NS_ASSUME_NONNULL_END
