//
//  ZNGContactService.m
//  Pods
//
//  Created by Robert Harrison on 5/23/16.
//
//

#import "ZNGContactService.h"

@implementation ZNGContactService

- (BOOL) isEqual:(ZNGContactService *)other
{
    if (![other isKindOfClass:[ZNGContactService class]]) {
        return NO;
    }
    
    return (([self.contactId isEqualToString:other.contactId]) && ([self.serviceId isEqualToString:other.serviceId]));
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"contactId" : @"contact_id",
             @"accountId" : @"account_id",
             @"serviceId" : @"service_id",
             @"unreadMessageCount" : @"unread_message_count",
             @"serviceDisplayName" : @"service_display_name",
             @"accountDisplayName" : @"account_display_name",
             @"lastMessage" : @"last_message"
             };
}

+ (NSValueTransformer*)lastMessageJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGMessage.class];
}

@end
