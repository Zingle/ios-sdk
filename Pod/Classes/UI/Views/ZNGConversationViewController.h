//
//  ZNGConversationViewController.h
//  Pods
//
//  Created by Jason Neel on 6/20/16.
//
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>

@class ZNGConversation;

@interface ZNGConversationViewController : JSQMessagesViewController

@property (nonatomic, strong, nullable) ZNGConversation * conversation;

@end
