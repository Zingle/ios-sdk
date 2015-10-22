//
//  ZNGAddress.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGAddress.h"
#import "ZingleModel.h"
#import "NSMutableDictionary+json.h"

@implementation ZNGAddress

- (id)init
{
    if( self = [super init] ) {
        self.address = @"";
        self.city = @"";
        self.state = @"";
        self.postalCode = @"";
        self.country = @"";
    }
    return self;
}

- (void)hydrate:(NSMutableDictionary *)data
{
    self.address = [data objectAtPath:@"address" expectedClass:[NSString class] default:@""];
    self.city = [data objectAtPath:@"city" expectedClass:[NSString class] default:@""];
    self.state = [data objectAtPath:@"state" expectedClass:[NSString class] default:@""];
    self.country = [data objectAtPath:@"country" expectedClass:[NSString class] default:@""];
    self.postalCode = [data objectAtPath:@"postal_code" expectedClass:[NSString class] default:@""];
}

- (NSMutableDictionary *)asDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setObject:self.address forKey:@"address"];
    [dictionary setObject:self.city forKey:@"city"];
    [dictionary setObject:self.state forKey:@"state"];
    [dictionary setObject:self.country forKey:@"country"];
    [dictionary setObject:self.postalCode forKey:@"postal_code"];
    
    return dictionary;
}

- (NSString *)description
{
    NSString *description = @"<ZNGAddress> {\r";
    description = [description stringByAppendingFormat:@"    address: %@\r", self.address];
    description = [description stringByAppendingFormat:@"    city: %@\r", self.city];
    description = [description stringByAppendingFormat:@"    state: %@\r", self.state];
    description = [description stringByAppendingFormat:@"    country: %@\r", self.country];
    description = [description stringByAppendingFormat:@"    postalCode: %@\r", self.postalCode];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}

@end
