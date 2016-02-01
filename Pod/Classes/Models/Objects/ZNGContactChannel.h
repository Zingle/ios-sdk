//
//  ZingleChannel.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZNGChannel.h"

@class ZNGChannelType;
@class ZNGContact;

@interface ZNGContactChannel : ZNGChannel

@property (nonatomic, retain) ZNGContact *contact;
@property (nonatomic, retain) NSString *displayName, *value, *formattedValue, *country;
@property (nonatomic, retain) ZNGChannelType *channelType;
@property (nonatomic) BOOL isDefault, isDefaultForType;

- (id)initWithContact:(ZNGContact *)contact;
- (void)deleteFromContactWithError:(NSError **)error;

@end
