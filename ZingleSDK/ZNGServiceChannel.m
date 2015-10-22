//
//  ZingleChannel.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGServiceChannel.h"
#import "ZingleSDK.h"
#import "ZingleModel.h"
#import "ZNGChannel.h"
#import "ZingleDAO.h"
#import "NSMutableDictionary+json.h"
#import "ZNGChannelType.h"
#import "ZNGService.h"

@implementation ZNGServiceChannel

- (id)init
{
    if( self = [super init] )
    {
        [self initDefaults];
    }
    return self;
}

- (id)initWithService:(ZNGService *)service
{
    if( self = [super init] )
    {
        [self initDefaults];
        self.service = service;
    }
    return self;
}

- (void)initDefaults
{
    self.service = nil;
    self.displayName = @"";
    self.value = @"";
    self.formattedValue = @"";
    self.country = @"";
    self.channelType = [[ZNGChannelType alloc] init];
    self.isDefaultForType = NO;
}

- (NSString *)baseURIWithID:(BOOL)withID
{
    if( withID ) {
        return [NSString stringWithFormat:@"services/%@/channels/%@", self.service.ID, self.ID];
    } else {
        return [NSString stringWithFormat:@"services/%@/channels", self.service.ID];
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
    self.isDefaultForType = [[data objectAtPath:@"is_default_for_type" expectedClass:[NSNumber class] default:[NSNumber numberWithBool:NO]] boolValue];
}

- (NSError *)preSaveValidation
{
    if( self.service == nil ) {
        return [[ZingleSDK sharedSDK] genericError:@"Cannot save when Service Channel has no Service set." code:0];
    }
    if( self.value == nil || [self.value isEqualToString:@""] ) {
        return [[ZingleSDK sharedSDK] genericError:@"Cannot save when Service Channel value is empty." code:0];
    }
    if( self.channelType == nil ) {
        return [[ZingleSDK sharedSDK] genericError:@"Cannot save when Service Channel has no Channel Type." code:0];
    }
    if( [self.channelType isNew] ) {
        return [[ZingleSDK sharedSDK] genericError:@"Cannot save with invalid Channel Type" code:0];
    }
    
    return nil;
}

- (NSMutableDictionary *)asDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setObject:self.channelType.ID forKey:@"channel_type_id"];
    [dictionary setObject:self.displayName forKey:@"display_name"];
    [dictionary setObject:self.value forKey:@"value"];
    [dictionary setObject:self.country forKey:@"country"];
    [dictionary setObject:[NSNumber numberWithBool:self.isDefaultForType] forKey:@"is_default_for_type"];

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

- (NSString *)description
{
    NSString *description = @"<ZNGServiceChannel> {\r";
    description = [description stringByAppendingFormat:@"    ID: %@\r", self.ID];
    description = [description stringByAppendingFormat:@"    Service ID: %@\r", self.service.ID];
    description = [description stringByAppendingFormat:@"    displayName: %@\r", self.displayName];
    description = [description stringByAppendingFormat:@"    channelType: %@\r", self.channelType];
    description = [description stringByAppendingFormat:@"    value: %@\r", self.value];
    description = [description stringByAppendingFormat:@"    formattedValue: %@\r", self.formattedValue];
    description = [description stringByAppendingFormat:@"    country: %@\r", self.country];
    description = [description stringByAppendingFormat:@"    isDefaultForType: %d\r", self.isDefaultForType];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}

@end
