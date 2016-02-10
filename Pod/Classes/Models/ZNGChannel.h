//
//  ZNGChannel.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGChannelType.h"

@interface ZNGChannel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *channelId;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, strong) NSString *formattedValue;
@property (nonatomic, strong) NSString *country;
@property (nonatomic) BOOL isDefaultForType;
@property (nonatomic, strong) ZNGChannelType *channelType;

@end
