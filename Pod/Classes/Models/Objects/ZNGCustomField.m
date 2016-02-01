//
//  ZNGCustomField.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGCustomField.h"
#import "ZingleModel.h"
#import "ZNGCustomFieldOption.h"
#import "NSMutableDictionary+json.h"
#import "ZNGCustomFieldOption.h"
#import "ZingleDAO.h"
#import "ZNGService.h"

@implementation ZNGCustomField

- (id)initWithService:(ZNGService *)service
{
    if( self = [super init] )
    {
        self.service = service;
    }
    return self;
}

- (NSString *)baseURIWithID:(BOOL)withID
{
    if( withID ) {
        return [NSString stringWithFormat:@"services/%@/contact-custom-fields/%@", self.service.ID, self.ID];
    } else {
        return [NSString stringWithFormat:@"services/%@/contact-custom-fields", self.service.ID];
    }
}

- (void)hydrate:(NSMutableDictionary *)data
{
    self.ID = [data objectAtPath:@"id" expectedClass:[NSString class] default:nil];
    self.displayName = [data objectAtPath:@"display_name" expectedClass:[NSString class] default:@""];
    self.isGlobal = [[data objectAtPath:@"is_global" expectedClass:[NSNumber class] default:[NSNumber numberWithBool:NO]] boolValue];
    
    NSArray *options = [data objectAtPath:@"options" expectedClass:[NSArray class] default:[NSArray array]];
    
    self.options = [NSMutableArray array];
    for( NSMutableDictionary *optionData in options )
    {
        ZNGCustomFieldOption *option = [[ZNGCustomFieldOption alloc] init];
        [option hydrate:[optionData mutableCopy]];
        [self.options addObject:option];
    }
}

- (void)preSaveValidation
{
    if( self.service == nil )
    {
        [NSException raise:@"ZINGLE_MISSING_SERVICE" format:@"No valid Service associated with object."];
    }
}

- (NSMutableDictionary *)asDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setObject:self.displayName forKey:@"display_name"];
    
    NSMutableArray *options = [NSMutableArray array];
    for( ZNGCustomFieldOption *option in self.options )
    {
        [options addObject:[option asDictionary]];
    }
    
    [dictionary setObject:options forKey:@"options"];
    
    return dictionary;
}

- (void)preDestroyValidation
{
    // OK
}

- (BOOL)deleteFromServiceWithError:(NSError **)error
{
    return [self destroyWithError:error];
}


- (ZNGCustomFieldOption *)customFieldOptionWithID:(NSString *)customFieldOptionID
{
    for( ZNGCustomFieldOption *option in self.options )
    {
        if( [option.ID isEqualToString:customFieldOptionID] )
        {
            return option;
        }
    }
    return nil;
}

- (NSString *)description
{
    NSString *description = @"<ZNGCustomField> {\r";
    description = [description stringByAppendingFormat:@"    ID: %@\r", self.ID];
    description = [description stringByAppendingFormat:@"    displayName: %@\r", self.displayName];
    description = [description stringByAppendingFormat:@"    isGlobal: %d\r", self.isGlobal];
    description = [description stringByAppendingFormat:@"    options: %@\r", self.options];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}


@end
