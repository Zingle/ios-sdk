//
//  ZNGCustomFieldOption.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGCustomFieldOption.h"
#import "NSMutableDictionary+json.h"

@implementation ZNGCustomFieldOption


- (void)hydrate:(NSMutableDictionary *)data
{
    self.ID = [data objectAtPath:@"id" expectedClass:[NSString class] default:nil];
    self.displayName = [data objectAtPath:@"display_name" expectedClass:[NSString class] default:@""];
    self.value = [data objectAtPath:@"value" expectedClass:[NSString class] default:@""];
    self.sortOrder = [data objectAtPath:@"sort_order" expectedClass:[NSNumber class] default:[NSNumber numberWithInt:0]];
}

- (NSMutableDictionary *)asDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if( self.ID != nil && [self.ID length] > 0 )
    {
        [dictionary setObject:self.ID forKey:@"id"];
    }
    [dictionary setObject:self.displayName forKey:@"display_name"];
    [dictionary setObject:self.value forKey:@"value"];
    [dictionary setObject:self.sortOrder forKey:@"sort_order"];
    
    return dictionary;
}


- (NSString *)description
{
    NSString *description = @"<ZNGCustomFieldOption> {\r";
    description = [description stringByAppendingFormat:@"    ID: %@\r", self.ID];
    description = [description stringByAppendingFormat:@"    displayName: %@\r", self.displayName];
    description = [description stringByAppendingFormat:@"    value: %@\r", self.value];
    description = [description stringByAppendingFormat:@"    sortOrder: %i\r", [self.sortOrder intValue]];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}

@end
