//
//  ZNGAvailablePhoneNumber.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGAvailablePhoneNumber.h"
#import "NSMutableDictionary+json.h"
#import "ZNGService.h"
#import "ZNGServiceChannel.h"
#import "ZNGChannelType.h"

@implementation ZNGAvailablePhoneNumber

- (id)initWithService:(ZNGService *)service
{
    if( self = [super init] )
    {
        self.service = service;
    }
    return self;
}

- (void)hydrate:(NSMutableDictionary *)data
{
    self.phoneNumber = [data objectAtPath:@"phone_number" expectedClass:[NSString class] default:@""];
    self.formattedPhoneNumber = [data objectAtPath:@"formatted_phone_number" expectedClass:[NSString class] default:@""];
    self.country = [data objectAtPath:@"country" expectedClass:[NSString class] default:@""];
}

- (ZNGServiceChannel *)newServiceChannel
{
    if( self.service == nil || [self.service isNew] )
    {
        [NSException raise:@"ZINGLE_MISSING_SERVICE" format:@"No valid Service associated with object."];
    }
    
    return [self newServiceChannelFor:self.service];
}

- (ZNGServiceChannel *)newServiceChannelFor:(ZNGService *)service
{
    ZNGChannelType *phoneNumberChannelType = [service firstChannelTypeWithClass:ZINGLE_CHANNEL_TYPE_CLASS_PHONE_NUMBER];
    
    ZNGServiceChannel *serviceChannel = [[ZNGServiceChannel alloc] initWithService:service];
    serviceChannel.channelType = phoneNumberChannelType;
    serviceChannel.displayName = @"";
    serviceChannel.value = self.phoneNumber;
    serviceChannel.formattedValue = self.formattedPhoneNumber;
    serviceChannel.country = self.country;
    serviceChannel.isDefaultForType = NO;
    
    return serviceChannel;
}

- (ZNGServiceChannel *)provisionAsServiceDefault:(BOOL)asDefault
{
    if( self.service == nil || [self.service isNew] )
    {
        [NSException raise:@"ZINGLE_MISSING_SERVICE" format:@"No valid Service associated with object."];
    }
    
    return [self provisionForService:self.service asServiceDefault:asDefault];
}

- (ZNGServiceChannel *)provisionForService:(ZNGService *)service asServiceDefault:(BOOL)asDefault
{
    ZNGServiceChannel *channel = [self newServiceChannelFor:service];
    channel.isDefaultForType = asDefault;
//    [channel save];
    return channel;
}

- (NSString *)description
{
    NSString *description = @"<ZNGAvailablePhoneNumber> {\r";
    if( self.service != nil && ![self.service isNew] )
    {
        description = [description stringByAppendingFormat:@"    Service ID: %@\r", self.service.ID];
    }
    description = [description stringByAppendingFormat:@"    phoneNumber: %@\r", self.phoneNumber];
    description = [description stringByAppendingFormat:@"    formattedPhoneNumber: %@\r", self.formattedPhoneNumber];
    description = [description stringByAppendingFormat:@"    country: %@\r", self.country];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}

@end
