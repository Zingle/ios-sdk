//
//  ZNGNewContactChannel.h
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import <ZingleSDK/ZingleSDK.h>
#import <Mantle/Mantle.h>
#import "ZNGContactChannel.h"

@interface ZNGNewContactChannel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *channelTypeId;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic) BOOL isDefaultForType;

- (id)initWithContactChannel:(ZNGContactChannel *)contactChannel;

@end
