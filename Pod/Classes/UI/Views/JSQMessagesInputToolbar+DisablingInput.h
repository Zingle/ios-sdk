//
//  JSQMessagesInputToolbar+DisablingInput.h
//  Pods
//
//  Created by Jason Neel on 8/15/16.
//
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>

@interface JSQMessagesInputToolbar (DisablingInput)

- (void) disableInput;
- (void) enableInput;
- (void) setSendButtonEnabled:(BOOL)enabled;

@end
