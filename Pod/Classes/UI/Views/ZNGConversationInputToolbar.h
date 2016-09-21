//
//  ZNGConversationInputToolbar.h
//  Pods
//
//  Created by Jason Neel on 9/19/16.
//
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>

@class ZNGConversationInputToolbar;

@protocol ZNGConversationInputToolbarDelegate <JSQMessagesInputToolbarDelegate>

@optional
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressAttachImageButton:(id)sender;

@end

@interface ZNGConversationInputToolbar : JSQMessagesInputToolbar

@property (nonatomic, assign) BOOL inputEnabled;
@property (nonatomic, readonly) UIButton * sendButton;

@end
