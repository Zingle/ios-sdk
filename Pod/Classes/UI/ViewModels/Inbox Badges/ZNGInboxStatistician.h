//
//  ZNGInboxStatistician.h
//  ZingleSDK
//
//  Created by Jason Neel on 1/23/18.
//

#import <Foundation/Foundation.h>

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
- (NSUInteger) openCountForTeam:(ZNGTeam *)team;
- (NSUInteger) openCountForUser:(ZNGUser *)user;
- (NSUInteger) unassignedOpenCount;

@end
