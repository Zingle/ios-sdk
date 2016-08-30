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
 *  Sets the value, clearing formatted value as appropriate.
 */
- (void) setValueFromTextEntry:(NSString *)newValue;

/**
 *  Returns YES if this channel has had its value or displayName changed since the older parameter.
 */
- (BOOL) changedSince:(ZNGChannel *)old;

/**
 *  If this is a phone number channel, this will return a string containing only numbers with a leading 1 removed.
 */
- (NSString *) valueForComparison;


@end