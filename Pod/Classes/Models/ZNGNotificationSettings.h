//
//  ZNGNotificationSettings.h
//  ZingleSDK
//
//  Created by Jason Neel on 3/8/18.
//

#import <Mantle/Mantle.h>

@interface ZNGNotificationSettings : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) uint32_t desktopMask;
@property (nonatomic, assign) uint32_t mobileMask;

@property (nonatomic, assign) BOOL receiveMobileUnassigned;
@property (nonatomic, assign) BOOL receiveMobileAllRelevantTeams;
@property (nonatomic, assign) BOOL receiveMobileAssignedToYou;

@end
