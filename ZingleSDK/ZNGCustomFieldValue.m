//
//  ZNGCustomFieldValue.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGCustomFieldValue.h"
#import "NSMutableDictionary+json.h"
#import "ZNGCustomField.h"
#import "ZNGCustomFieldOption.h"
#import "ZNGContact.h"
#import "ZNGService.h"
#import "ZingleDAO.h"

@implementation ZNGCustomFieldValue

- (id)initWithContact:(ZNGContact *)contact
{
    if( self = [super init] )
    {
        self.contact = contact;
        self.customField = [[ZNGCustomField alloc] init];
    }
    return self;
}

- (id)initWithService:(ZNGService *)service
{
    if( self = [super init] )
    {
        self.service = service;
        self.customField = [[ZNGCustomField alloc] init];
    }
    return self;
}

- (NSString *)baseURIWithID:(BOOL)withID
{
    if( self.service != nil ) {
        if( withID ) {
            return [NSString stringWithFormat:@"services/%@/custom-field-values/%@", self.service.ID, self.ID];
        } else {
            return [NSString stringWithFormat:@"services/%@/custom-field-values", self.service.ID];
        }
    } else if( self.contact != nil ) {
        if( withID ) {
            return [NSString stringWithFormat:@"services/%@/contacts/%@/custom-field-values/%@", self.contact.service.ID, self.contact.ID, self.ID];
        } else {
            return [NSString stringWithFormat:@"services/%@/contacts/%@/custom-field-values", self.contact.service.ID, self.contact.ID];
        }
    }
    return @"";
}

- (void)hydrate:(NSMutableDictionary *)data
{
    self.ID = [data objectAtPath:@"id" expectedClass:[NSString class] default:nil];
    
    NSMutableDictionary *customFieldData = [[data objectAtPath:@"custom_field" expectedClass:[NSDictionary class] default:[NSMutableDictionary dictionary]] mutableCopy];
    
    self.customField = [[ZNGCustomField alloc] init];
    [self.customField hydrate:customFieldData];
    
    _selectedCustomFieldOptionId = [data objectAtPath:@"selected_custom_field_option_id" expectedClass:[NSString class] default:nil];
    
    _value = [data objectAtPath:@"value" expectedClass:[NSString class] default:@""];
}

- (void)preSaveValidation
{
    if( [self.customField isNew] )
    {
        [NSException raise:@"ZINGLE_MISSING" format:@"Custom Field ID required."];
    }
    
    if( !( (self.contact != nil && self.service == nil) ||
           (self.service != nil && self.contact == nil) ) )
    {
        [NSException raise:@"ZINGLE_MISSING" format:@"Either a Contact or Service is required on object."];
    }
}

- (void)setValue:(NSString *)value
{
    _selectedCustomFieldOptionId = nil;
    _value = value;
}

- (void)setSelectedCustomFieldOptionId:(NSString *)selectedCustomFieldOptionId
{
    self.value = nil;
    
    if( selectedCustomFieldOptionId == nil )
    {
        _selectedCustomFieldOptionId = nil;
        return;
    }
    
    ZNGCustomFieldOption *option = [self.customField customFieldOptionWithID:selectedCustomFieldOptionId];
    
    if( option == nil )
    {
        [NSException raise:@"ZINGLE_UNKNOWN_OPTION" format:@"Invalid Custom Field Option ID for Custom Field."];
    }
    
    self.value = nil;
    _selectedCustomFieldOptionId = selectedCustomFieldOptionId;
}

- (NSMutableDictionary *)asDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if( self.service == nil ) {
        [dictionary setObject:self.customField.ID forKey:@"custom_field_id"];
    } else {
        [dictionary setObject:self.customField.ID forKey:@"settings_field_id"];
    }
    
    if( self.value != nil )
    {
        [dictionary setObject:self.value forKey:@"value"];
    }
    else if( self.selectedCustomFieldOptionId != nil )
    {
        [dictionary setObject:self.selectedCustomFieldOptionId forKey:@"selected_custom_field_option_id"];
    }
    
    return dictionary;
}

- (ZNGCustomFieldOption *)selectedCustomFieldOption
{
    if( self.selectedCustomFieldOptionId != nil )
    {
        return [self.customField customFieldOptionWithID:self.selectedCustomFieldOptionId];
    }
    return nil;
}

- (NSString *)description
{
    NSString *description = @"<ZNGCustomFieldValue> {\r";
    description = [description stringByAppendingFormat:@"    customField: %@\r", self.customField];
    description = [description stringByAppendingFormat:@"    selectedCustomFieldOption: %@\r", [self selectedCustomFieldOption]];
    description = [description stringByAppendingFormat:@"    value: %@\r", self.value];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}

@end
