//
//  ZNGNewServiceChannel.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <ZingleSDK/ZingleSDK.h>
#import <Mantle/Mantle.h>
#import "ZNGServiceChannel.h"

@interface ZNGNewServiceChannel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *channelTypeId;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic) BOOL isDefaultForType;

- (id)initWithServiceChannel:(ZNGServiceChannel *)serviceChannel;

@end
