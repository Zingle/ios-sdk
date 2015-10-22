//
//  ZNGChannelType.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGChannelType.h"
#import "NSMutableDictionary+json.h"

NSString * const ZINGLE_CHANNEL_TYPE_CLASS_PHONE_NUMBER = @"PhoneNumber";
NSString * const ZINGLE_CHANNEL_TYPE_CLASS_EMAIL_ADDRESS = @"EmailAddress";
NSString * const ZINGLE_CHANNEL_TYPE_CLASS_USER_DEFINED = @"UserDefined";

@implementation ZNGChannelType

- (void)hydrate:(NSMutableDictionary *)data
{
    self.ID = [data objectAtPath:@"id" expectedClass:[NSString class] default:@""];
    self.typeClass = [data objectAtPath:@"type_class" expectedClass:[NSString class] default:@""];
    self.displayName = [data objectAtPath:@"display_name" expectedClass:[NSString class] default:@""];
    self.inboundNotificationURL = [data objectAtPath:@"inbound_notification_url" expectedClass:[NSString class] default:nil];
    self.outboundNotificationURL = [data objectAtPath:@"outbound_notification_url" expectedClass:[NSString class] default:nil];
    self.allowCommunications = [[data objectAtPath:@"allow_communications" expectedClass:[NSNumber class] default:[NSNumber numberWithBool:NO]] boolValue];
}


- (NSMutableDictionary *)asDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if( self.ID != nil && ![self.ID isEqualToString:@""] ) {
        [dictionary setObject:self.ID forKey:@"id"];
    }
    if( self.typeClass != nil && ![self.typeClass isEqualToString:@""] ) {
        [dictionary setObject:self.typeClass forKey:@"type_class"];
    }
    if( self.displayName != nil && ![self.displayName isEqualToString:@""] ) {
        [dictionary setObject:self.displayName forKey:@"display_name"];
    }
    if( self.inboundNotificationURL != nil && ![self.inboundNotificationURL isEqualToString:@""] ) {
        [dictionary setObject:self.inboundNotificationURL forKey:@"inbound_notification_url"];
    }
    if( self.outboundNotificationURL != nil && ![self.outboundNotificationURL isEqualToString:@""] ) {
        [dictionary setObject:self.outboundNotificationURL forKey:@"outbound_notification_url"];
    }
    
    [dictionary setObject:[NSNumber numberWithBool:self.allowCommunications] forKey:@"allow_communications"];
    
    return dictionary;
}


- (NSString *)description
{
    NSString *description = @"<ZNGChannelType> {\r";
    description = [description stringByAppendingFormat:@"    id: %@\r", self.ID];
    description = [description stringByAppendingFormat:@"    typeClass: %@\r", self.typeClass];
    description = [description stringByAppendingFormat:@"    displayName: %@\r", self.displayName];
    description = [description stringByAppendingFormat:@"    inboundNotificationURL: %@\r", self.inboundNotificationURL];
    description = [description stringByAppendingFormat:@"    outboundNotificationURL: %@\r", self.outboundNotificationURL];
    description = [description stringByAppendingFormat:@"    allowCommunications: %d\r", self.allowCommunications];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}


@end
