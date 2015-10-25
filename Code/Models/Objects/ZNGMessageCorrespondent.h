//
//  ZNGMessageCorrespondent.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleModel.h"

extern NSString * const ZINGLE_CORRESPONDENT_TYPE_SERVICE;
extern NSString * const ZINGLE_CORRESPONDENT_TYPE_CONTACT;
extern NSString * const ZINGLE_CORRESPONDENT_TYPE_LABEL;

@class ZNGService;
@class ZNGContact;
@class ZNGLabel;
@class ZNGChannelType;

@interface ZNGMessageCorrespondent : ZingleModel

@property (nonatomic, retain) ZingleModel *correspondent;
@property (nonatomic, retain) NSString *channelValue, *formattedChannelValue, *correspondentType;
@property (nonatomic, retain) ZNGChannelType *channelType;


@end
