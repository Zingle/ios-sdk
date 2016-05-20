//
//  ZNGEvent.m
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import "ZNGEvent.h"
#import "ZingleValueTransformers.h"

@implementation ZNGEvent

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"eventId" : @"id",
             @"contactId" : @"contact_id",
             @"eventType" : @"event_type",
             @"body" : @"body",
             @"createdAt" : @"created_at",
             @"triggeredByUser" : @"triggered_by_user",
             @"automation" : @"automation",
             @"message" : @"message"
             };
}

+ (NSValueTransformer*)createdAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer*)triggeredByUserJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGUser.class];
}

+ (NSValueTransformer*)automationJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGAutomation.class];
}

+ (NSValueTransformer*)messageJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGMessage.class];
}

@end
