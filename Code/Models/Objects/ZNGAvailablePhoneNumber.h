//
//  ZNGAvailablePhoneNumber.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleModel.h"

@class ZNGService;
@class ZNGServiceChannel;

@interface ZNGAvailablePhoneNumber : ZingleModel

@property (nonatomic, retain) ZNGService *service;
@property (nonatomic, retain) NSString *phoneNumber, *formattedPhoneNumber, *country;

- (id)initWithService:(ZNGService *)service;
- (ZNGServiceChannel *)newServiceChannel;
- (ZNGServiceChannel *)newServiceChannelFor:(ZNGService *)service;
- (ZNGServiceChannel *)provisionAsServiceDefault:(BOOL)asDefault;
- (ZNGServiceChannel *)provisionForService:(ZNGService *)service asServiceDefault:(BOOL)asDefault;

@end
