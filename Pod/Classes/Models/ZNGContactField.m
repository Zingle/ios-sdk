//
//  ZNGContactField.m
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGContactField.h"
#import "ZNGFieldOption.h"

@implementation ZNGContactField

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"contactFieldId" : @"id",
             @"displayName" : @"display_name",
             @"dataType" : @"data_type",
             @"isGlobal" : @"is_global",
             @"options" : @"options",
             @"replacementVariable" : @"replacement_variable"
             };
}

+ (NSValueTransformer*)optionsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGFieldOption.class];
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

@end
