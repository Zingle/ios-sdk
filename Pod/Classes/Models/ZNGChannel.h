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

@property(nonatomic, strong) NSString* channelId;
@property(nonatomic, strong) NSString* displayName;
@property(nonatomic, strong) NSString* value;
@property(nonatomic, strong) NSString* formattedValue;
@property(nonatomic, strong) NSString* country;
@property(nonatomic) BOOL isDefault;
@property(nonatomic) BOOL isDefaultForType;
@property(nonatomic, strong) ZNGChannelType* channelType;

/**
 *  Returns YES if this channel is of a phone number type
 */
- (BOOL) isPhoneNumber;

/**
 *  A string represent the channel type, such as "MOBILE" or "Custom Channel Type Name."
 *  Guaranteed never to be nil.
 */
- (NSString *) channelTypeDescription;

@end