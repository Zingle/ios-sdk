//
//  ZNGContact.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZingleModel.h"

extern NSString * const ZINGLE_CUSTOM_FIELD_TITLE;
extern NSString * const ZINGLE_CUSTOM_FIELD_FIRST_NAME;
extern NSString * const ZINGLE_CUSTOM_FIELD_LAST_NAME;

@class ZNGCustomFieldValue;
@class ZNGContactChannel;
@class ZNGService;
@class ZNGMessage;
@class ZNGChannelType;

@interface ZNGContact : ZingleModel

@property (nonatomic, retain) ZNGService *service;
@property (nonatomic, retain) NSString *title, *firstName, *lastName;
@property (nonatomic, retain) NSMutableArray *channels, *customFieldValues, *labels;
@property (nonatomic) BOOL isConfirmed, isStarred, isClosed;

- (id)initWithService:(ZNGService *)service;
- (ZNGContactChannel *)newChannel;
- (ZNGCustomFieldValue *)customFieldValueForName:(NSString *)customFieldDisplayName globalOnly:(BOOL)globalOnly;
- (ZNGCustomFieldValue *)customFieldValueForID:(NSString *)customFieldID;

- (void)setCustomFieldValueTo:(NSString *)value forCustomFieldWithName:(NSString *)customFieldDisplayName;
- (void)setSelectedCustomFieldOptionIDTo:(NSString *)selectedCustomFieldOptionID forCustomFieldWithName:(NSString *)customFieldDisplayName;

- (void)setChannelValueTo:(NSString *)value forChannelTypeWithName:(NSString *)channelTypeName;


- (ZNGChannelType *)channelTypeForName:(NSString *)channelTypeDisplayName;
- (ZNGChannelType *)channelTypeForID:(NSString *)channelTypeID;

- (ZNGMessage *)newMessageToContact;
- (ZNGMessage *)newMessageFromContact;
- (ZNGMessage *)newMessageFrom:(ZingleModel *)senderModel to:(ZingleModel *)recipientModel;

@end
