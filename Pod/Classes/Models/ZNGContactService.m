//
//  ZNGContactService.m
//  Pods
//
//  Created by Robert Harrison on 5/23/16.
//
//

#import "ZNGContactService.h"
#import "ZingleValueTransformers.h"

@implementation ZNGContactService

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"contactId" : @"contact_id",
             @"accountId" : @"account_id",
             @"serviceId" : @"service_id",
             @"unreadMessageCount" : @"unread_message_count",
             @"serviceDisplayName" : @"service_display_name",
             @"accountDisplayName" : @"account_display_name",
             @"lastMessage" : @"last_message",
             @"createdAt" : @"created_at",
             @"updatedAt" : @"updated_at"
             };
}

+ (NSValueTransformer*)lastMessageJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGMessage.class];
}

+ (NSValueTransformer*)createdAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer*)updatedAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

@end
