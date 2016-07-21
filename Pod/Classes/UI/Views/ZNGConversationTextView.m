//
//  ZNGConversationTextView.m
//  Pods
//
//  Created by Jason Neel on 7/21/16.
//
//

#import "ZNGConversationTextView.h"

// Private method to configure views because JSQ is a jerk
@interface JSQMessagesComposerTextView()
- (void)jsq_configureTextView;
@end

@implementation ZNGConversationTextView

- (void) jsq_configureTextView
{
    [super jsq_configureTextView];
    
    self.layer.borderWidth = 0.0;
    self.layer.borderColor = nil;
    self.layer.cornerRadius = 0.0;
    
    self.scrollIndicatorInsets = UIEdgeInsetsZero;
}

@end
