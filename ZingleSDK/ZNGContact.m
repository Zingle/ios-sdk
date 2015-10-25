//
//  ZNGContact.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGContact.h"
#import "ZingleModel.h"
#import "NSMutableDictionary+json.h"
#import "ZNGCustomField.h"
#import "ZNGCustomFieldValue.h"
#import "ZNGContactChannel.h"
#import "ZNGLabel.h"
#import "ZNGService.h"
#import "ZingleDAO.h"
#import "ZingleSDK.h"
#import "ZNGMessage.h"
#import "ZNGMessageCorrespondent.h"
#import "ZNGChannelType.h"

NSString * const ZINGLE_CUSTOM_FIELD_TITLE = @"Title";
NSString * const ZINGLE_CUSTOM_FIELD_FIRST_NAME = @"First Name";
NSString * const ZINGLE_CUSTOM_FIELD_LAST_NAME = @"Last Name";

@implementation ZNGContact


- (id)init
{
    if( self = [super init] ) {
        [self initDefaults];
    }
    return self;
}

- (id)initWithService:(ZNGService *)service
{
    if( self = [super init] ) {
        [self initDefaults];
        self.service = service;
    }
    return self;
}

- (void)initDefaults
{
    self.service = nil;
    self.title = @"";
    self.firstName = @"";
    self.lastName = @"";
    self.channels = [NSMutableArray array];
    self.customFieldValues = [NSMutableArray array];
    self.labels = [NSMutableArray array];
    self.isConfirmed = YES;
    self.isStarred = NO;
    self.isClosed = NO;
}

- (NSString *)baseURIWithID:(BOOL)withID
{
    if( withID ) {
        return [NSString stringWithFormat:@"services/%@/contacts/%@", self.service.ID, self.ID];
    } else {
        return [NSString stringWithFormat:@"services/%@/contacts", self.service.ID];
    }
}

- (void)hydrate:(NSMutableDictionary *)data
{
    [self hydrateDates:data];
    
    self.ID = [data objectAtPath:@"id" expectedClass:[NSString class] default:nil];
    self.isConfirmed = [[data objectAtPath:@"is_confirmed" expectedClass:[NSNumber class] default:[NSNumber numberWithBool:NO]] boolValue];
    self.isStarred = [[data objectAtPath:@"is_starred" expectedClass:[NSNumber class] default:[NSNumber numberWithBool:NO]] boolValue];
    
    NSArray *channels = [data objectAtPath:@"channels" expectedClass:[NSArray class] default:[NSArray array]];
    
    self.channels = [NSMutableArray array];
    for( id channelData in channels )
    {
        ZNGContactChannel *channel = [[ZNGContactChannel alloc] initWithContact:self];
        [channel hydrate:[channelData mutableCopy]];
        [self.channels addObject:channel];
    }
    
    NSArray *customFieldValues = [data objectAtPath:@"custom_field_values" expectedClass:[NSArray class] default:[NSArray array]];
    
    self.customFieldValues = [NSMutableArray array];
    for( id customFieldValueData in customFieldValues )
    {
        ZNGCustomFieldValue *customFieldValue = [[ZNGCustomFieldValue alloc] initWithContact:self];
        [customFieldValue hydrate:[customFieldValueData mutableCopy]];
        [self.customFieldValues addObject:customFieldValue];
    }
    
    NSArray *labels = [data objectAtPath:@"labels" expectedClass:[NSArray class] default:[NSArray array]];
    
    self.labels = [NSMutableArray array];
    for( id labelData in labels )
    {
        ZNGLabel *label = [[ZNGLabel alloc] init];
        [label hydrate:[labelData mutableCopy]];
        [self.labels addObject:label];
    }
    
    ZNGCustomFieldValue *title = [self customFieldValueForName:ZINGLE_CUSTOM_FIELD_TITLE globalOnly:YES];
    if( title != nil )
    {
        self.title = title.value;
    }
    
    ZNGCustomFieldValue *firstName = [self customFieldValueForName:ZINGLE_CUSTOM_FIELD_FIRST_NAME globalOnly:YES];
    if( firstName != nil )
    {
        self.firstName = firstName.value;
    }
    
    ZNGCustomFieldValue *lastName = [self customFieldValueForName:ZINGLE_CUSTOM_FIELD_LAST_NAME globalOnly:YES];
    if( lastName != nil )
    {
        self.lastName = lastName.value;
    }
}

- (NSError *)preSaveValidation
{
    if( self.service == nil ) {
        return [[ZingleSDK sharedSDK] genericError:@"Cannot save Contact without a Service." code:0];
    }
    
    return nil;
}

- (NSMutableDictionary *)asDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setObject:[NSNumber numberWithBool:self.isStarred] forKey:@"is_starred"];
    [dictionary setObject:[NSNumber numberWithBool:self.isConfirmed] forKey:@"is_confirmed"];
    [dictionary setObject:[NSNumber numberWithBool:self.isClosed] forKey:@"is_closed"];
    
    NSMutableArray *customFieldValues = [NSMutableArray array];
    for( ZNGCustomFieldValue *value in self.customFieldValues ) {
        [customFieldValues addObject:[value asDictionary]];
    }
    [dictionary setObject:customFieldValues forKey:@"custom_field_values"];
    
    NSMutableArray *channels = [NSMutableArray array];
    for( ZNGContactChannel *channel in self.channels ) {
        [channels addObject:[channel asDictionary]];
    }
    [dictionary setObject:channels forKey:@"channels"];
    
    return dictionary;
}

- (void)setCustomFieldValueTo:(NSString *)value forCustomFieldWithName:(NSString *)customFieldDisplayName
{
    ZNGCustomFieldValue *customFieldValue = [self customFieldValueForName:customFieldDisplayName globalOnly:NO];
    
    if( customFieldValue == nil ) {
        customFieldValue = [[ZNGCustomFieldValue alloc] initWithContact:self];
        customFieldValue.customField = [self.service getCustomFieldByDisplayName:customFieldDisplayName];
        [self.customFieldValues addObject:customFieldValue];
    }
    
    customFieldValue.value = value;
}

- (void)setSelectedCustomFieldOptionIDTo:(NSString *)selectedCustomFieldOptionID forCustomFieldWithName:(NSString *)customFieldDisplayName
{
    ZNGCustomFieldValue *customFieldValue = [self customFieldValueForName:customFieldDisplayName globalOnly:NO];
    
    if( customFieldValue == nil ) {
        customFieldValue = [[ZNGCustomFieldValue alloc] initWithContact:self];
        customFieldValue.customField = [self.service getCustomFieldByDisplayName:customFieldDisplayName];
        [self.customFieldValues addObject:customFieldValue];
    }
    
    customFieldValue.value = nil;
    customFieldValue.selectedCustomFieldOptionId = selectedCustomFieldOptionID;
}

- (ZNGCustomFieldValue *)customFieldValueForName:(NSString *)customFieldDisplayName globalOnly:(BOOL)globalOnly
{
    for( ZNGCustomFieldValue *value in self.customFieldValues )
    {
        if( [value.customField.displayName isEqualToString:customFieldDisplayName] &&
            (!globalOnly || value.customField.isGlobal) )
        {
            return value;
        }
    }
    
    return nil;
}

- (ZNGCustomFieldValue *)customFieldValueForID:(NSString *)customFieldID
{
    for( ZNGCustomFieldValue *value in self.customFieldValues )
    {
        if( [value.customField.ID isEqualToString:customFieldID] )
        {
            return value;
        }
    }
    
    return nil;
}


- (void)setChannelValueTo:(NSString *)value forChannelTypeWithName:(NSString *)channelTypeName
{
    ZNGChannelType *channelType = [self channelTypeForName:channelTypeName];
    ZNGContactChannel *channel;
    
    if( channelType != nil ) {
        for( ZNGContactChannel *contactChannel in self.channels ) {
            if( [contactChannel.channelType.ID isEqualToString:channelType.ID] ) {
                channel = contactChannel;
                break;
            }
        }
        
        if( channel == nil ) {
            channel = [[ZNGContactChannel alloc] initWithContact:self];
            channel.channelType = channelType;
            
            [self.channels addObject:channel];
        }
        
        channel.value = value;
    }
}


- (ZNGChannelType *)channelTypeForName:(NSString *)channelTypeDisplayName
{
    if( self.service ) {
        for( ZNGChannelType *channelType in self.service.channelTypes ) {
            if( [channelType.displayName isEqualToString:channelTypeDisplayName] ) {
                return channelType;
            }
        }
    }
    
    return nil;
}

- (ZNGChannelType *)channelTypeForID:(NSString *)channelTypeID
{
    if( self.service ) {
        for( ZNGChannelType *channelType in self.service.channelTypes ) {
            if( [channelType.ID isEqualToString:channelTypeID] ) {
                return channelType;
            }
        }
    }
    
    return nil;
}

- (ZNGContactChannel *)newChannel
{
    ZNGContactChannel *contactChannel = [[ZNGContactChannel alloc] initWithContact:self];
    [self.channels addObject:contactChannel];
    return contactChannel;
}

- (ZNGMessage *)newMessageToContact
{
    return [self newMessageFrom:self.service to:self];
}

- (ZNGMessage *)newMessageFromContact
{
    return [self newMessageFrom:self to:self.service];
}

- (ZNGMessage *)newMessageFrom:(ZingleModel *)senderModel to:(ZingleModel *)recipientModel
{
    ZNGMessage *message = [[ZNGMessage alloc] initWithService:self.service];
    
    ZNGMessageCorrespondent *sender = [[ZNGMessageCorrespondent alloc] init];
    [sender setCorrespondent:senderModel];
    
    ZNGMessageCorrespondent *recipient = [[ZNGMessageCorrespondent alloc] init];
    [recipient setCorrespondent:recipientModel];
    
    [message setSender:sender];
    [message setRecipient:recipient];
    
    return message;
}

- (NSString *)description
{
    NSString *description = @"<ZNGContact> {\r";
    description = [description stringByAppendingFormat:@"    ID: %@\r", self.ID];
    description = [description stringByAppendingFormat:@"    service: %@\r", self.service];
    description = [description stringByAppendingFormat:@"    title: %@\r", self.title];
    description = [description stringByAppendingFormat:@"    firstName: %@\r", self.firstName];
    description = [description stringByAppendingFormat:@"    lastName: %@\r", self.lastName];
    description = [description stringByAppendingFormat:@"    isConfirmed: %d\r", self.isConfirmed];
    description = [description stringByAppendingFormat:@"    isStarred: %d\r", self.isStarred];
    description = [description stringByAppendingFormat:@"    channels: %@\r", self.channels];
    description = [description stringByAppendingFormat:@"    customFieldValues: %@\r", self.customFieldValues];
    description = [description stringByAppendingFormat:@"    labels: %@\r", self.labels];
    description = [description stringByAppendingFormat:@"    created: %@\r", self.created];
    description = [description stringByAppendingFormat:@"    updated: %@\r", self.updated];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}

@end
