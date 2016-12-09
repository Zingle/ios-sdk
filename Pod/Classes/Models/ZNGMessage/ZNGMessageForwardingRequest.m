//
//  ZNGMessageForwardingRequest.m
//  Pods
//
//  Created by Jason Neel on 12/8/16.
//
//

#import "ZNGMessageForwardingRequest.h"
#import "ZNGMessage.h"

NSString * const ZNGMessageForwardingRecipientTypeSMS = @"sms";
NSString * const ZNGMessageForwardingRecipientTypeEmail = @"email";
NSString * const ZNGMessageForwardingRecipientTypeHotsos = @"hotsos";
NSString * const ZNGMessageForwardingRecipientTypeService = @"service";

@implementation ZNGMessageForwardingRequest

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(body)) : @"body",
             NSStringFromSelector(@selector(recipientType)) : @"recipient_type",
             NSStringFromSelector(@selector(recipient)) : @"recipient",
             NSStringFromSelector(@selector(hotsosIssue)) : @"hotsos_issue",
             NSStringFromSelector(@selector(room)) : @"room",
             NSStringFromSelector(@selector(message)) : [NSNull null]
             };
}

- (NSString *)body
{
    return self.message.body;
}

@end
