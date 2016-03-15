//
//  ZNGContact.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGContact.h"
#import "ZingleValueTransformers.h"
#import "ZNGContactFieldValue.h"
#import "ZNGLabel.h"

@implementation ZNGContact

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"contactId" : @"id",
             @"isConfirmed" : @"is_confirmed",
             @"isStarred" : @"is_starred",
             @"lastMessage" : @"last_communication",
             @"channels" : @"channels",
             @"customFieldValues" : @"custom_field_values",
             @"labels" : @"labels",
             @"createdAt" : @"created_at",
             @"updatedAt" : @"udpated_at"
             };
}

+ (NSValueTransformer*)lastMessageJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGMessage.class];
}

+ (NSValueTransformer*)channelsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGChannel.class];
}

+ (NSValueTransformer*)customFieldValuesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGContactFieldValue.class];
}

+ (NSValueTransformer*)labelsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGLabel.class];
}

+ (NSValueTransformer*)createdAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer*)updatedAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

-(NSString *)title
{
    for (ZNGContactFieldValue *fieldValue in self.customFieldValues) {
        if ([fieldValue.customField.displayName isEqualToString:@"Title"]) {
            return fieldValue.value;
        }
    }
    return nil;
}

-(NSString *)firstName
{
    for (ZNGContactFieldValue *fieldValue in self.customFieldValues) {
        if ([fieldValue.customField.displayName isEqualToString:@"First Name"]) {
            return fieldValue.value;
        }
    }
    return nil;
}

-(NSString *)lastName
{
    for (ZNGContactFieldValue *fieldValue in self.customFieldValues) {
        if ([fieldValue.customField.displayName isEqualToString:@"Last Name"]) {
            return fieldValue.value;
        }
    }
    return nil;
}

-(NSString *)phoneNumber
{
    for (ZNGChannel *channel in self.channels) {
        if ([channel.channelType.typeClass isEqualToString:@"PhoneNumber"]) {
            return channel.formattedValue;
        }
    }
    return nil;
}

@end
