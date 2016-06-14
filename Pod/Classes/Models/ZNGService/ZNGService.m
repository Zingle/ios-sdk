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

@implementation ZNGService

- (BOOL) isEqual:(ZNGService *)other
{
    if (![other isKindOfClass:[ZNGService class]]) {
        return NO;
    }
    
    return (self.serviceId == other.serviceId);
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

- (ZNGChannelType *)channelTypeWithDisplayName:(NSString *)channelDisplayName
{
    for (ZNGChannelType *channelType in self.channelTypes) {
        if ([channelDisplayName isEqualToString:channelType.displayName]) {
            return channelType;
        }
    }
    return nil;
}


@end
