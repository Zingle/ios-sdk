//
//  ZNGConversation.h
//  ZingleSDK
//
//  Copyright © 2015 Zingle.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZNGService;
@class ZNGContact;
@class ZNGMessageCorrespondent;
@class ZNGChannelType;

@interface ZNGConversation : NSObject

@property (nonatomic, retain) ZNGMessageCorrespondent *from, *to;
@property (nonatomic, retain) ZNGChannelType *channelType;

- (id)initWithFrom:(ZNGMessageCorrespondent *)from to:(ZNGMessageCorrespondent *)to usingChannelType:(ZNGChannelType *)channelType;

@end
