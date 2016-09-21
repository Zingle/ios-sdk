//
//  ZNGConversationInputToolbar.m
//  Pods
//
//  Created by Jason Neel on 9/19/16.
//
//

#import "ZNGConversationInputToolbar.h"

@implementation ZNGConversationInputToolbar

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
