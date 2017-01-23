//
//  ZNGMessageForwardingRequest.h
//  Pods
//
//  Created by Jason Neel on 12/8/16.
//
//

#import <Mantle/Mantle.h>

@class ZNGMessage;

extern NSString * const ZNGMessageForwardingRecipientTypeSMS;
extern NSString * const ZNGMessageForwardingRecipientTypeEmail;
extern NSString * const ZNGMessageForwardingRecipientTypeHotsos;
extern NSString * const ZNGMessageForwardingRecipientTypeService;
extern NSString * const ZNGMessageForwardingRecipientTypePrinter;

@interface ZNGMessageForwardingRequest : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) NSString * body;
@property (nonatomic, strong) NSString * recipientType; // hotsos, sms, email, or service
@property (nonatomic, strong) NSArray<NSString *> * recipients; // phone numbers, email addresses, or service IDs (homogeneous of type)
@property (nonatomic, strong) NSString * hotsosIssue;   // HotSOS issue name
@property (nonatomic, strong) NSString * room;  // Contact room number

@property (nonatomic, strong) ZNGMessage * message;

@end
