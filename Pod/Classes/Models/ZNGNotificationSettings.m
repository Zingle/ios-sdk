//
//  ZNGNotificationSettings.m
//  ZingleSDK
//
//  Created by Jason Neel on 3/8/18.
//

#import "ZNGNotificationSettings.h"

enum {
    NOTIFICATION_MASK_UNASSIGNED = 1 << 0,
    NOTIFICATION_MASK_ASSIGNED_TO_YOU = 1 << 1,
    NOTIFICATION_MASK_ALL_RELEVANT_TEAMS = 1 << 2,
};

@implementation ZNGNotificationSettings

+ (NSDictionary *) JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(mobileMask)): @"mobile",
             NSStringFromSelector(@selector(desktopMask)): @"desktop",
             };
}

#pragma mark - Computed properties
- (BOOL) receiveMobileAssignedToYou
{
    return (self.mobileMask & NOTIFICATION_MASK_ASSIGNED_TO_YOU);
}

- (BOOL) receiveMobileUnassigned
{
    return (self.mobileMask & NOTIFICATION_MASK_UNASSIGNED);
}

- (BOOL) receiveMobileAllRelevantTeams
{
    return (self.mobileMask & NOTIFICATION_MASK_ALL_RELEVANT_TEAMS);
}

- (void) setReceiveMobileAssignedToYou:(BOOL)receiveMobileOthers
{
    self.mobileMask = [self _valueFrom:self.mobileMask settingBitsBehindMask:NOTIFICATION_MASK_ASSIGNED_TO_YOU toValue:receiveMobileOthers];
}

- (void) setReceiveMobileUnassigned:(BOOL)receiveMobileUnassigned
{
    self.mobileMask = [self _valueFrom:self.mobileMask settingBitsBehindMask:NOTIFICATION_MASK_UNASSIGNED toValue:receiveMobileUnassigned];
}

- (void) setReceiveMobileAllRelevantTeams:(BOOL)receiveMobileAllRelevantTeams
{
    self.mobileMask = [self _valueFrom:self.mobileMask settingBitsBehindMask:NOTIFICATION_MASK_ALL_RELEVANT_TEAMS toValue:receiveMobileAllRelevantTeams];
}

- (uint32_t) _valueFrom:(uint32_t)value settingBitsBehindMask:(uint32_t)mask toValue:(BOOL)set
{
    if (set) {
        return value | mask;
    }
    
    return value & ~mask;
}

@end
