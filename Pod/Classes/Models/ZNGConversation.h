//
//  ZNGConversation.h
//  Pods
//
//  Created by Ryan Farley on 2/18/16.
//
//

#import <Foundation/Foundation.h>
#import "ZNGParticipant.h"
#import "ZNGError.h"

@protocol ZNGConversationDelegate <NSObject>

- (void)messagesUpdated;

@end

@interface ZNGConversation : NSObject

@property (nonatomic, strong) NSString *channelTypeId;
@property (nonatomic, strong) ZNGParticipant *contact;
@property (nonatomic, strong) ZNGParticipant *service;
@property (nonatomic, strong) NSArray *messages;
@property (nonatomic,weak) id<ZNGConversationDelegate> delegate;

- (void)updateMessages;

@end
