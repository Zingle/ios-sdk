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
@property(nonatomic) BOOL blockInbound;
@property(nonatomic) BOOL blockOutbound;
@property(nonatomic, strong) ZNGChannelType* channelType;

/**
 *  Returns YES if this channel is of a phone number type
 */
- (BOOL) isPhoneNumber;

/**
 *  Returns YES if this channel is of email type
 */
- (BOOL) isEmail;

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

// These are separate methods because of http://jira.zinglecorp.com:8080/browse/TECH-1970 and its code that must live in
//  the service object to determine which value to display for phone numbers.  Gross.
- (NSString *) displayValueUsingRawValue;
- (NSString *) displayValueUsingFormattedValue;


@end