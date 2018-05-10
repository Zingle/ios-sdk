//
//  ZNGUserSettings.h
//  ZingleSDK
//
//  Created by Jason Neel on 4/20/18.
//

#import <Mantle/Mantle.h>

@interface ZNGUserSettings : MTLModel <MTLJSONSerializing>

// Properties are NSNumber instead of BOOL to allow nullability and defaulting in getter methods

/**
 *  When this is `@YES`, inbox UI should only display users that share one or more teams with the current user.
 *  Defaults to `@YES`.
 */
@property (nonatomic, strong, nullable) NSNumber * showOnlyMyTeammates;

/**
 *  When this is `@YES`, an unassigned inbox should be available to the user in servies with assignment enabled.
 *  Defaults to nil.
 */
@property (nonatomic, strong, nullable) NSNumber * showUnassignedConversations;

@end
