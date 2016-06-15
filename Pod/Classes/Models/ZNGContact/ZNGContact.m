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
             @"lastMessage" : @"last_message",
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

-(ZNGContactFieldValue *)titleFieldValue
{
    for (ZNGContactFieldValue *fieldValue in self.customFieldValues) {
        if ([fieldValue.customField.displayName isEqualToString:@"Title"]) {
            return fieldValue;
        }
    }
    ZNGContactFieldValue *fieldValue = [[ZNGContactFieldValue alloc] init];
    fieldValue.customField = [[ZNGContactField alloc] init];
    fieldValue.customField.displayName = @"Title";
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.customFieldValues];
    [array addObject:fieldValue];
    self.customFieldValues = array;
    return fieldValue;
}

-(ZNGContactFieldValue *)firstNameFieldValue
{
    for (ZNGContactFieldValue *fieldValue in self.customFieldValues) {
        if ([fieldValue.customField.displayName isEqualToString:@"First Name"]) {
            return fieldValue;
        }
    }
    ZNGContactFieldValue *fieldValue = [[ZNGContactFieldValue alloc] init];
    fieldValue.customField = [[ZNGContactField alloc] init];
    fieldValue.customField.displayName = @"First Name";
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.customFieldValues];
    [array addObject:fieldValue];
    self.customFieldValues = array;
    return fieldValue;
}

-(ZNGContactFieldValue *)lastNameFieldValue
{
    for (ZNGContactFieldValue *fieldValue in self.customFieldValues) {
        if ([fieldValue.customField.displayName isEqualToString:@"Last Name"]) {
            return fieldValue;
        }
    }
    ZNGContactFieldValue *fieldValue = [[ZNGContactFieldValue alloc] init];
    fieldValue.customField = [[ZNGContactField alloc] init];
    fieldValue.customField.displayName = @"Last Name";
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.customFieldValues];
    [array addObject:fieldValue];
    self.customFieldValues = array;
    return fieldValue;
}

-(ZNGChannel *)phoneNumberChannel
{
    for (ZNGChannel *channel in self.channels) {
        if ([channel.channelType.typeClass isEqualToString:@"PhoneNumber"]) {
            return channel;
        }
    }
    return nil;
}

- (ZNGChannel *)channelForFreshOutgoingMessage
{
    if (self.lastMessage != nil) {
        // We have a message to or from this person.  Let's return that same channel.
        
        // Outgoing or incoming?
        ZNGCorrespondent * dude = ([self.lastMessage isOutbound]) ? self.lastMessage.recipient : self.lastMessage.sender;
        return dude.channel;
    }
    
    
    // We resort to finding a phone number channel if possible
    ZNGChannel * phoneChannel = nil;
    
    for (ZNGChannel * channel in self.channels) {
        if ([channel.channelType.typeClass isEqualToString:@"PhoneNumber"]) {
            phoneChannel = channel;
            
            if (phoneChannel.isDefaultForType) {
                return phoneChannel;
            }
        }
    }
    
    return phoneChannel;
}

- (NSString *)fullName
{
    NSString *title = [self titleFieldValue].value;
    NSString *firstName = [self firstNameFieldValue].value;
    NSString *lastName = [self lastNameFieldValue].value;
    
    if(firstName.length < 1 && lastName.length < 1)
    {
        NSString *phoneNumber = [self phoneNumberChannel].formattedValue;
        if (phoneNumber) {
            return phoneNumber;
        } else {
            return @"Anonymous User";
        }
    }
    else
    {
        NSString *name = @"";
        
        if(title.length > 0)
        {
            name = [name stringByAppendingString:[NSString stringWithFormat:@"%@ ", title]];
        }
        if(firstName.length > 0)
        {
            name = [name stringByAppendingString:[NSString stringWithFormat:@"%@ ", firstName]];
        }
        if(lastName.length > 0)
        {
            name = [name stringByAppendingString:lastName];
        }
        return name;
    }
}

- (BOOL)requiresVisualRefeshSince:(ZNGContact *)old
{
    return ((old.lastMessage == self.lastMessage) &&
            ([[old fullName] isEqualToString:[self fullName]]) &&
            (old.isStarred == self.isStarred) &&
            (old.isConfirmed == self.isConfirmed) &&
            ([old.labels isEqualToArray:self.labels]));
}

@end
