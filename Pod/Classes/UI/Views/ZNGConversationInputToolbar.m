//
//  ZNGConversationInputToolbar.m
//  Pods
//
//  Created by Jason Neel on 9/19/16.
//
//

#import "ZNGConversationInputToolbar.h"

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

- (void) commonInit
{
    _inputEnabled = YES;
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
        self.contentView.textView.text = @"";
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
