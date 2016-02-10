//
//  ZNGNewContact.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGNewContact.h"
#import "ZNGContactFieldValue.h"

@implementation ZNGNewContact

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"customFieldValues" : @"custom_field_values",
             @"isStarred" : @"is_starred",
             @"isConfirmed" : @"is_confirmed"
             };
}

- (id)initWithContact:(ZNGContact*)contact
{
    self = [super init];
    
    if (self) {
        _customFieldValues = contact.customFieldValues;
        _isStarred = contact.isStarred;
        _isConfirmed = contact.isConfirmed;
    }
    
    return self;
}

+ (NSValueTransformer*)customFieldValuesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGContactFieldValue.class];
}

@end
