//
//  ZNGSetting.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGSetting.h"
#import "ZNGFieldOption.h"

@implementation ZNGSetting

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"settingId" : @"id",
             @"displayName" : @"display_name",
             @"dataType" : @"data_type",
             @"options" : @"options"
             };
}

+ (NSValueTransformer *)optionsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGFieldOption.class];
}

@end
