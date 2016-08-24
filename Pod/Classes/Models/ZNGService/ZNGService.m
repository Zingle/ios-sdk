//
//  ZNGService.m
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import "ZNGService.h"
#import "ZingleValueTransformers.h"
#import "ZNGChannel.h"
#import "ZNGLabel.h"
#import "ZNGContactField.h"
#import "ZNGSetting.h"
#import "ZNGAutomation.h"
#import "ZNGTemplate.h"

@implementation ZNGService

- (BOOL) isEqual:(ZNGService *)other
{
    if (![other isKindOfClass:[ZNGService class]]) {
        return NO;
    }
    
    return ([self.serviceId isEqualToString:other.serviceId]);
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"%@ (%@)", self.displayName, [self class]];
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"serviceId" : @"id",
             @"displayName" : @"display_name",
             @"businessName" : @"business_name",
             @"timeZone" : @"time_zone",
             @"account" : @"account",
             @"plan" : @"plan",
             @"channels" : @"channels",
             @"channelTypes" : @"channel_types",
             @"contactLabels" : @"contact_labels",
             @"contactCustomFields" : @"contact_custom_fields",
             @"settings" : @"settings",
             @"automations" : @"automations",
             @"templates" : @"templates",
             @"serviceAddress" : @"service_address",
             @"createdAt" : @"created_at",
             @"updatedAt" : @"updated_at"
             };
}

+ (NSValueTransformer*)accountJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGAccount.class];
}

+ (NSValueTransformer*)planJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGAccountPlan.class];
}

+ (NSValueTransformer*)channelsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGChannel.class];
}

+ (NSValueTransformer*)channelTypesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGChannelType.class];
}

+ (NSValueTransformer*)contactLabelsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGLabel.class];
}

+ (NSValueTransformer*)contactCustomFieldsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGContactField.class];
}

+ (NSValueTransformer*)settingsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGSetting.class];
}

+ (NSValueTransformer *)automationsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGAutomation class]];
}

+ (NSValueTransformer *)templatesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGTemplate class]];
}

+ (NSValueTransformer*)serviceAddressJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGServiceAddress.class];
}

+ (NSValueTransformer*)createdAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer*)updatedAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

- (NSString*)resourceId
{
    return self.serviceId;
}

- (ZNGChannelType *)phoneNumberChannelType
{
    NSUInteger index = [self.channelTypes indexOfObjectPassingTest:^BOOL(ZNGChannelType * _Nonnull channelType, NSUInteger idx, BOOL * _Nonnull stop) {
        return [channelType isPhoneNumberType];
    }];
    
    if (index == NSNotFound) {
        return nil;
    }
    
    return self.channelTypes[index];
}

- (ZNGChannelType *)channelTypeWithDisplayName:(NSString *)channelDisplayName
{
    for (ZNGChannelType *channelType in self.channelTypes) {
        if ([channelDisplayName isEqualToString:channelType.displayName]) {
            return channelType;
        }
    }
    return nil;
}

- (ZNGChannelType *)channelTypeWithTypeClass:(NSString *)typeClass
{
    for (ZNGChannelType * channelType in self.channelTypes) {
        if ([channelType.typeClass isEqualToString:typeClass]) {
            return channelType;
        }
    }
    return nil;
}

- (ZNGChannel *)defaultPhoneNumberChannel
{
    return [self defaultChannelForType:[self phoneNumberChannelType]];
}

- (ZNGChannel *)defaultChannelForType:(ZNGChannelType *)channelType
{
    ZNGChannel * chosenChannel = nil;
    
    for (ZNGChannel * channel in self.channels) {
        if ([channel.channelType.channelTypeId isEqualToString:channelType.channelTypeId]) {
            chosenChannel = channel;
            
            if (chosenChannel.isDefaultForType) {
                break;
            }
        }
    }
    
    return chosenChannel;
}

/**
 *  Thanks to http://jira.zinglecorp.com:8080/browse/TECH-1970, there is logic for displaying a channel
 *   that depends on the country code for the channel vs. the service.  This is gross and I hate it.
 */
- (NSString *) displayNameForChannel:(ZNGChannel *)channel
{
    NSString * country = self.serviceAddress.country;
    
    if ((country != nil) && ([channel isPhoneNumber])) {
        if (![country isEqualToString:channel.country]) {
            // We have a phone number from a different country.  Show the raw value.
            return channel.value;
        }
    }
    
    return channel.formattedValue;
}


@end
