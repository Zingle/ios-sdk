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
#import "ZNGTeam.h"
#import "ZNGTemplate.h"
#import "ZNGSettingsField.h"
#import "ZNGPrinter.h"
#import "ZNGContactGroup.h"

#define kServiceSettingHotsosURLKey         @"hotsos_url"
#define kServiceSettingHotsosUserNameKey    @"hotsos_username"
#define kServiceSettingHotsosPasswordKey    @"hotsos_password"

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
             NSStringFromSelector(@selector(features)): @"features",
             @"settings" : @"settings",
             @"automations" : @"automations",
             @"printers" : @"printers",
             NSStringFromSelector(@selector(contactGroups)): @"contact_groups",
             NSStringFromSelector(@selector(teams)): @"teams",
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
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ZNGAccount class]];
}

+ (NSValueTransformer*)planJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ZNGAccountPlan class]];
}

+ (NSValueTransformer*)channelsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGChannel class]];
}

+ (NSValueTransformer*)channelTypesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGChannelType class]];
}

+ (NSValueTransformer*)contactLabelsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGLabel class]];
}

+ (NSValueTransformer*)contactCustomFieldsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGContactField class]];
}

+ (NSValueTransformer*)settingsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGSetting class]];
}

+ (NSValueTransformer *)automationsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGAutomation class]];
}

+ (NSValueTransformer *)teamsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGTeam class]];
}

+ (NSValueTransformer *)templatesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGTemplate class]];
}

+ (NSValueTransformer *)printersJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGPrinter class]];
}

+ (NSValueTransformer *) contactGroupsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGContactGroup class]];
}

+ (NSValueTransformer*)serviceAddressJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ZNGServiceAddress class]];
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

- (NSArray<ZNGAutomation *> *)activeAutomations
{
    NSMutableArray<ZNGAutomation *> * automations = [[NSMutableArray alloc] initWithCapacity:[self.automations count]];
    
    for (ZNGAutomation * automation in self.automations) {
        if ([automation isActive]) {
            [automations addObject:automation];
        }
    }
    
    return automations;
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
    
    // Enumerate the channels backwards so we end up with the first channel if none are marked as default
    for (ZNGChannel * channel in [self.channels reverseObjectEnumerator]) {
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

- (NSString *) settingValueForCode:(NSString *)code
{
    for (ZNGSetting * setting in self.settings) {
        if ([setting.settingsField.code isEqualToString:code]) {
            return setting.value;
        }
    }
    
    return nil;
}

- (ZNGSetting * _Nullable)settingWithCode:(NSString * _Nonnull)settingCode
{
    for (ZNGSetting * setting in self.settings) {
        if ([setting.settingsField.code isEqualToString:settingCode]) {
            return setting;
        }
    }
    
    return nil;
}

- (BOOL) allowsAssignment
{
    ZNGSetting * assignmentSetting = [self settingWithCode:@"assignment_enabled"];
    
    // First check if the setting is enabled.
    // It is possible for the service to have the feature but also have the feature disabled via the setting.
    if (![assignmentSetting.value boolValue]) {
        return NO;
    }
    
    // We're in nonsense land if the assignment_enabled setting is true above but the feature is missing.
    // We'll check anyway.
    return ([self.features containsObject:@"assignment"]);
}

- (BOOL) allowsTeamAssignment
{
    if (![self allowsAssignment]) {
        // Assignment in general is not allowed.  Team assignment certainly is not.
        return NO;
    }
    
    return ([self.features containsObject:@"teams"]);
}

- (NSString *)hotsosHostName
{
    return [self settingValueForCode:kServiceSettingHotsosURLKey];
}

- (NSString *)hotsosUserName
{
    return [self settingValueForCode:kServiceSettingHotsosUserNameKey];
}

- (NSString *)hotsosPassword
{
    return [self settingValueForCode:kServiceSettingHotsosPasswordKey];
}

@end
