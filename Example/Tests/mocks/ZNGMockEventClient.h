//
//  ZNGMockEventClient.h
//  ZingleSDK
//
//  Created by Jason Neel on 3/7/17.
//  Copyright © 2017 Zingle. All rights reserved.
//

#import <ZingleSDK/ZNGEventClient.h>

@class ZNGEvent;

@interface ZNGMockEventClient : ZNGEventClient

/**
 *  Events to be returned by spoofed methods, ordered oldest to newest (i.e. opposite of normal ZNGConversation ordering)
 */
@property (nonatomic, strong, nullable) NSArray<ZNGEvent *> * events;

@end
