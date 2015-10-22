//
//  ZingleChannel.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGContactChannel.h"
#import "ZNGChannel.h"
#import "ZingleModel.h"
#import "ZingleDAO.h"
#import "ZingleSDK.h"
#import "NSMutableDictionary+json.h"
#import "ZNGChannelType.h"
#import "ZNGContact.h"
#import "ZNGService.h"

@implementation ZNGContactChannel

- (id)initWithContact:(ZNGContact *)contact
{
    if( self = [super init] )
    {
        self.contact = contact;
        self.channelType = [[ZNGChannelType alloc] init];
        self.displayName = @"";
        self.value = @"";
        self.formattedValue = @"";
        self.country = @"";
    }
    return self;
}

- (NSString *)baseURIWithID:(BOOL)withID
{
    if( withID ) {
        return [NSString stringWithFormat:@"services/%@/contacts/%@/channels/%@", self.contact.service.ID, self.contact.ID, self.ID];
    } else {
        return [NSString stringWithFormat:@"services/%@/contacts/%@/channels", self.contact.service.ID, self.contact.ID];
    }
}

- (void)hydrate:(NSMutableDictionary *)data
{
    self.ID = [data objectAtPath:@"id" expectedClass:[NSString class] default:nil];
    self.displayName = [data objectAtPath:@"display_name" expectedClass:[NSString class] default:@""];
    
    NSMutableDictionary *channelTypeData = [data objectAtPath:@"channel_type" expectedClass:[NSDictionary class] default:[NSMutableDictionary dictionary]];
    self.channelType = [[ZNGChannelType alloc] init];
    [self.channelType hydrate:channelTypeData];
    
    self.value = [data objectAtPath:@"value" expectedClass:[NSString class] default:@""];
    self.formattedValue = [data objectAtPath:@"formatted_value" expectedClass:[NSString class] default:@""];
    self.country = [data objectAtPath:@"country" expectedClass:[NSString class] default:@""];
    self.isDefault = [[data objectAtPath:@"is_default" expectedClass:[NSNumber class] default:[NSNumber numberWithBool:NO]] boolValue];
    self.isDefaultForType = [[data objectAtPath:@"is_default_for_type" expectedClass:[NSNumber class] default:[NSNumber numberWithBool:NO]] boolValue];
}

- (NSError *)preSaveValidation
{
    if( self.contact == nil )
    {
        return [[ZingleSDK sharedSDK] genericError:@"No contact associated with object." code:0];
    }
    if( self.channelType == nil || [self.channelType isNew] )
    {
        return [[ZingleSDK sharedSDK] genericError:@"No valid Channel Type associated with object." code:0];
    }
    
    return nil;
}

- (NSMutableDictionary *)asDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setObject:self.value forKey:@"value"];
    [dictionary setObject:self.country forKey:@"country"];
    [dictionary setObject:self.channelType.ID forKey:@"channel_type_id"];
    
    return dictionary;
}

- (void)preDestroyValidation
{
    // OK
}

- (void)deleteFromContactWithError:(NSError **)error
{
    [self destroyWithError:error];
}

- (NSString *)description
{
    NSString *description = @"<ZNGContactChannel> {\r";
    description = [description stringByAppendingFormat:@"    ID: %@\r", self.ID];
    description = [description stringByAppendingFormat:@"    Contact ID: %@\r", self.contact.ID];
    description = [description stringByAppendingFormat:@"    displayName: %@\r", self.displayName];
    description = [description stringByAppendingFormat:@"    channelType: %@\r", self.channelType];
    description = [description stringByAppendingFormat:@"    value: %@\r", self.value];
    description = [description stringByAppendingFormat:@"    formattedValue: %@\r", self.formattedValue];
    description = [description stringByAppendingFormat:@"    country: %@\r", self.country];
    description = [description stringByAppendingFormat:@"    isDefault: %d\r", self.isDefault];
    description = [description stringByAppendingFormat:@"    isDefaultForType: %d\r", self.isDefaultForType];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}

@end
