//
//  JSQMessagesInputToolbar+DisablingInput.m
//  Pods
//
//  Created by Jason Neel on 8/15/16.
//
//

#import "JSQMessagesInputToolbar+DisablingInput.h"

@implementation JSQMessagesInputToolbar (DisablingInput)

- (UIButton *) _sendButton
{
    if (self.sendButtonOnRight) {
        return self.contentView.rightBarButtonItem;
    }
    
    return self.contentView.leftBarButtonItem;
}

- (void) setSendButtonEnabled:(BOOL)enabled {
    [[self _sendButton] setEnabled:enabled];
}

- (void) disableInput
{
    self.contentView.textView.text = @"";
    self.contentView.textView.editable = NO;
    [[self _sendButton] setEnabled:NO];
}

- (void) enableInput
{
    self.contentView.textView.editable = YES;
    [[self _sendButton] setEnabled:YES];
}

@end
