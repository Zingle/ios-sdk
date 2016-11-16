//
//  ZNGNewMessage.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGParticipant.h"

@interface ZNGNewMessage : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* senderType;
@property(nonatomic, strong) ZNGParticipant* sender;
@property(nonatomic, strong) NSString* recipientType;
@property(nonatomic, strong) NSArray<ZNGParticipant *> * recipients;
@property(nonatomic, strong) NSArray* channelTypeIds; // Array of NSString
@property(nonatomic, strong) NSString* body;
@property(nonatomic, strong) NSArray* attachments;

/**
 *  Outgoing image attachments for local rendering
 */
@property(nonatomic, strong) NSArray<UIImage *> * outgoingImageAttachments;

@end
