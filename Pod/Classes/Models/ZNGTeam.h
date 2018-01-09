//
//  ZNGTeam.h
//  ZingleSDK
//
//  Created by Jason Neel on 1/4/18.
//

#import <Mantle/Mantle.h>

@interface ZNGTeam : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nullable) NSString * teamId;
@property (nonatomic, strong, nullable) NSDate * createdAt;
@property (nonatomic, strong, nullable) NSArray<NSString *> * userIds;
@property (nonatomic, copy, nullable) NSString * displayName;
@property (nonatomic, copy, nullable) NSString * emoji;

- (NSString * _Nullable) displayNameWithEmoji;

@end
