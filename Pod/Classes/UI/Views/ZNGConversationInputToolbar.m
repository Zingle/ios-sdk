//
//  ZNGConversationInputToolbar.m
//  Pods
//
//  Created by Jason Neel on 9/19/16.
//
//

#import "ZNGConversationInputToolbar.h"
#import "UIColor+ZingleSDK.h"

@implementation ZNGConversationInputToolbar

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (void) setSendButtonColor:(UIColor *)sendButtonColor
{
    _sendButtonColor = sendButtonColor;
    
    if (sendButtonColor != nil) {
        [[self sendButton] setTitleColor:sendButtonColor forState:UIControlStateNormal];
        [[self sendButton] setTitleColor:[sendButtonColor zng_colorByDarkeningColorWithValue:0.1] forState:UIControlStateHighlighted];
        [[self sendButton] setTintColor:sendButtonColor];
    }
}

- (void) setSendButtonFont:(UIFont *)sendButtonFont
{
    _sendButtonFont = sendButtonFont;
    
    if (sendButtonFont != nil) {
        UIButton * sendButton = [self sendButton];
        
        sendButton.titleLabel.font = sendButtonFont;
        
        CGSize sendButtonSize = [sendButton intrinsicContentSize];
        self.contentView.rightBarButtonItemWidth = sendButtonSize.width;
    }
}

- (void) commonInit
{
    _inputEnabled = YES;
    
    // Call the send button color setter again to actually color the button.
    if (self.sendButtonColor) {
        self.sendButtonColor = self.sendButtonColor;
    }
    
    if (self.sendButtonFont) {
        self.sendButtonFont = self.sendButtonFont;
    }
}

- (void) setInputEnabled:(BOOL)inputEnabled
{
    _inputEnabled = inputEnabled;
    [self toggleSendButtonEnabled];
}

- (void) toggleSendButtonEnabled
{
    if (self.inputEnabled) {
        self.contentView.textView.editable = YES;
        [super toggleSendButtonEnabled];
    } else {
        self.contentView.textView.editable = NO;
        self.sendButton.enabled = NO;
    }
}

- (UIButton *) sendButton
{
    if (self.sendButtonOnRight) {
        return self.contentView.rightBarButtonItem;
    }
    
    return self.contentView.leftBarButtonItem;
}

@end
