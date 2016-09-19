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

- (BOOL) isTextRelay
{
    return [self.plan isTextRelay];
}

+ (NSValueTransformer*)accountJSONTransformer
{
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[ZNGAccount class]];
}

+ (NSValueTransformer*)planJSONTransformer
{
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[ZNGAccountPlan class]];
}

+ (NSValueTransformer*)channelsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[ZNGChannel class]];
}

+ (NSValueTransformer*)channelTypesJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[ZNGChannelType class]];

}

+ (NSValueTransformer*)contactLabelsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[ZNGLabel class]];

}

+ (NSValueTransformer*)contactCustomFieldsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[ZNGContactField class]];
}

+ (NSValueTransformer*)settingsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[ZNGSetting class]];
}

+ (NSValueTransformer *)automationsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[ZNGAutomation class]];
}

+ (NSValueTransformer *)templatesJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[ZNGTemplate class]];
}

+ (NSValueTransformer*)serviceAddressJSONTransformer
{
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[ZNGServiceAddress class]];
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
- (BOOL) shouldDisplayRawValueForChannel:(ZNGChannel *)channel
{
    if (![channel isPhoneNumber]) {
        return NO;
    }
    
    NSString * country = self.serviceAddress.country;
    NSString * channelCountry = channel.country;
    
    return (([country length] > 0) && ([channelCountry length] > 0) && (![country isEqualToString:channelCountry]));
}


@end
