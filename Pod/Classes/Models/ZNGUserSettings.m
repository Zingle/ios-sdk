//
//  ZNGUserSettings.m
//  ZingleSDK
//
//  Created by Jason Neel on 4/20/18.
//

#import "ZNGUserSettings.h"

@implementation ZNGUserSettings

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(showOnlyMyTeammates)): @"show_only_my_teammates",
             NSStringFromSelector(@selector(showUnassignedConversations)): @"show_unassigned_conversations",
             };
}

// Default to YES for showUnassignedConversations
- (NSNumber *) showUnassignedConversations
{
    if (_showUnassignedConversations == nil) {
        return @YES;
    }

    return _showUnassignedConversations;
}

// Default to YES for showOnlyMyTeammates
- (NSNumber *) showOnlyMyTeammates
{
    if (_showOnlyMyTeammates == nil) {
        return @YES;
    }
    
    return _showOnlyMyTeammates;
}

@end
