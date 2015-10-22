//
//  ZNGChannelType.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleModel.h"

extern NSString * const ZINGLE_CHANNEL_TYPE_CLASS_PHONE_NUMBER;
extern NSString * const ZINGLE_CHANNEL_TYPE_CLASS_EMAIL_ADDRESS;
extern NSString * const ZINGLE_CHANNEL_TYPE_CLASS_USER_DEFINED;


@interface ZNGChannelType : ZingleModel

@property (nonatomic, retain) NSString *displayName, *typeClass, *inboundNotificationURL, *outboundNotificationURL;
@property (nonatomic) BOOL allowCommunications;

@end
