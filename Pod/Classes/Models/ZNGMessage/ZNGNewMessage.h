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

@property (nonatomic, strong) NSString *senderType;
@property (nonatomic, strong) ZNGSender *sender;
@property (nonatomic, strong) NSString *recipientType;
//Array of ZNGRecipient
@property (nonatomic, strong) NSArray *recipients;
//Array of NSStrings
@property (nonatomic, strong) NSArray *channelTypeIds;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSArray *attachments;

@end
