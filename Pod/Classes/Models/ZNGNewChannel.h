//
//  ZNGNewChannel.h
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGChannel.h"

@interface ZNGNewChannel : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* channelTypeId;
@property(nonatomic, strong) NSString* value;
@property(nonatomic, strong) NSString* country;
@property(nonatomic, strong) NSString* displayName;
@property(nonatomic) BOOL isDefaultForType;

- (instancetype)initWithChannel:(ZNGChannel*)channel;

@end
