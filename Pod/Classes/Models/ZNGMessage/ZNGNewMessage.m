//
//  ZNGNewMessage.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGNewMessage.h"
#import "ZNGCorrespondent.h"
#import "ZNGRecipient.h"

@implementation ZNGNewMessage

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
  return @{
    @"senderType" : @"sender_type",
    @"sender" : @"sender",
    @"recipientType" : @"recipient_type",
    @"recipients" : @"recipients",
    @"channelTypeIds" : @"channel_type_ids",
    @"body" : @"body",
    @"attachments" : @"attachments"
  };
}

+ (NSValueTransformer*)senderJSONTransformer {
  return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGSender.class];
}

+ (NSValueTransformer*)recipientsJSONTransformer {
  return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGRecipient.class];
}

@end
