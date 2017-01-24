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
NSString * const ZNGMessageForwardingRecipientTypePrinter = @"printer";

@implementation ZNGMessageForwardingRequest

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(body)) : @"body",
             NSStringFromSelector(@selector(recipientType)) : @"recipient_type",
             NSStringFromSelector(@selector(recipients)) : @"recipients",
             NSStringFromSelector(@selector(hotsosIssue)) : @"hotsos_issue",
             NSStringFromSelector(@selector(room)) : @"room",
             NSStringFromSelector(@selector(message)) : [NSNull null]
             };
}

- (void) setMessage:(ZNGMessage *)message
{
    _message = message;
    
    if ([self.body length] == 0) {
        self.body = message.body;
    }
}

@end
