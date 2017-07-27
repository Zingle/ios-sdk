//
//  ZNGSetting.m
//  Pods
//
//  Created by Jason Neel on 12/1/16.
//
//

#import "ZNGSetting.h"
#import "ZNGSettingsField.h"

@implementation ZNGSetting

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(value)) : @"value",
             NSStringFromSelector(@selector(settingsFieldOptionId)) : @"settings_field_option_id",
             NSStringFromSelector(@selector(settingsField)) : @"settings_field"
             };
}

+ (NSValueTransformer *) settingsFieldJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ZNGSettingsField class]];
}

@end
