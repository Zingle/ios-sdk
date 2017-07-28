//
//  ZNGContactField.m
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGContactField.h"
#import "ZNGFieldOption.h"

NSString * const ZNGContactFieldDataTypeString = @"string";
NSString * const ZNGContactFieldDataTypeNumber = @"number";
NSString * const ZNGContactFieldDataTypeBool = @"boolean";
NSString * const ZNGContactFieldDataTypeDate = @"date";
NSString * const ZNGContactFieldDataTypeTime = @"time";
NSString * const ZNGContactFieldDataTypeSingleSelect = @"single_select_options";

@implementation ZNGContactField

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"contactFieldId" : @"id",
             @"displayName" : @"display_name",
             @"code" : @"code",
             @"dataType" : @"data_type",
             @"isGlobal" : @"is_global",
             @"options" : @"options",
             @"replacementVariable" : @"replacement_variable"
             };
}

+ (NSValueTransformer*)optionsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGFieldOption class]];
}

- (BOOL) isEqual:(ZNGContactField *)object
{
    if (![object isKindOfClass:[ZNGContactField class]]) {
        return NO;
    }
    
    return (([self.contactFieldId isEqualToString:object.contactFieldId]) || ([self.displayName isEqualToString:object.displayName]));
}

- (NSUInteger) hash
{
    return [self.displayName hash];
}

- (BOOL) shouldCapitalizeEveryWord
{
    return (([[self.displayName lowercaseString] containsString:@"name"]) || ([[self.displayName lowercaseString] containsString:@"title"]));
}

@end
