//
//  ZNGConversationToolbarContentView.h
//  Pods
//
//  Created by Jason Neel on 7/18/16.
//
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>
#import "ZNGConversationTextView.h"

@interface ZNGConversationToolbarContentView : JSQMessagesToolbarContentView

@property (nonatomic, strong, nullable) IBOutlet UIButton * messageModeButton;
@property (nonatomic, strong, nullable) IBOutlet UIButton * templateButton;
@property (nonatomic, strong, nullable) IBOutlet UIButton * customFieldButton;
@property (nonatomic, strong, nullable) IBOutlet UIButton * automationButton;
@property (nonatomic, strong, nullable) IBOutlet UIButton * imageButton;
@property (nonatomic, strong, nullable) IBOutlet UIButton * atButton;
@property (nonatomic, strong, nullable) IBOutlet UIButton * noteButton;
@property (nonatomic, strong, nullable) IBOutlet UIButton * channelSelectButton;
@property (nonatomic, strong, nullable) IBOutlet UIButton * channelSelectArrow;
@property (nonatomic, strong, nullable) IBOutlet UIView * channelSelectContainer;

@property (nonatomic, strong, nullable) IBOutlet UIStackView * buttonStackView;

@property (weak, nonatomic, readonly, nullable) ZNGConversationTextView * textView;

- (void) enableOrDisableAllEditingButtons:(BOOL)enabled;

/**
 Enable/show one of the toolbar's `UIButton`s, e.g. `self.messageModeButton` or `self.imageButton`
 */
- (void) enableButton:(nonnull UIButton *)button;

/**
 Disable/hide one of the toolbar's `UIButton`s, e.g. `self.messageModeButton` or `self.imageButton`
 */
- (void) disableButton:(nonnull UIButton *)button;

@end
