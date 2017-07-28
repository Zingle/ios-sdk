//
//  ZNGNewContact.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGNewContact.h"
#import "ZNGNewContactFieldValue.h"

@implementation ZNGNewContact

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"customFieldValues" : @"custom_field_values"
             };
}

- (id)initWithContact:(ZNGContact*)contact
{
    self = [super init];
    
    if (self) {
        _customFieldValues = contact.customFieldValues;
    }
    
    return self;
}

+ (NSValueTransformer*)customFieldValuesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGNewContactFieldValue class]];
}

@end
