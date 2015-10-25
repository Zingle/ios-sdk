//
//  ZingleChannel.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZNGChannel.h"

@class ZNGChannelType;
@class ZNGService;

@interface ZNGServiceChannel : ZNGChannel

@property (nonatomic, retain) ZNGService *service;
@property (nonatomic, retain) NSString *displayName, *value, *formattedValue, *country;
@property (nonatomic, retain) ZNGChannelType *channelType;
@property (nonatomic) BOOL isDefaultForType;

- (id)initWithService:(ZNGService *)service;
- (BOOL)deleteFromServiceWithError:(NSError **)error;

@end
