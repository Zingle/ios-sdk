//
//  ZNGUserSettings.h
//  ZingleSDK
//
//  Created by Jason Neel on 4/20/18.
//

#import <Mantle/Mantle.h>

@interface ZNGUserSettings : MTLModel <MTLJSONSerializing>

// Properties are NSNumber instead of BOOL to allow nullability and YES-defaulting in getter methods
@property (nonatomic, strong, nullable) NSNumber * showOnlyMyTeammates;
@property (nonatomic, strong, nullable) NSNumber * showUnassignedConversations;

@end
