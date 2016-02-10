//
//  ZNGNewMessage.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGSender.h"

@interface ZNGNewMessage : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* senderType;
@property(nonatomic, strong) ZNGSender* sender;
@property(nonatomic, strong) NSString* recipientType;
@property(nonatomic, strong) NSArray* recipients; // Array of ZNGRecipient
@property(nonatomic, strong) NSArray* channelTypeIds; // Array of NSString
@property(nonatomic, strong) NSString* body;
@property(nonatomic, strong) NSArray* attachments;

@end
