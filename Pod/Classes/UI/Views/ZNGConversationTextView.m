//
//  ZNGConversationTextView.m
//  Pods
//
//  Created by Jason Neel on 7/21/16.
//
//

#import "ZNGConversationTextView.h"
#import "ZNGLogging.h"

static const int zngLogLevel = ZNGLogLevelWarning;

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

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    
    BOOL canPerform = NO;
    
    if ([self.text length] == 0) {
        if (action == @selector(paste:)) {
            canPerform = YES;
        }
    } else  {
        NSRange range = self.selectedRange;
        if (range.length > 0) {
            if (action == @selector(cut:) || action == @selector(copy:) ||
                action == @selector(select:) || action == @selector(selectAll:) ||
                action == @selector(paste:) || action ==@selector(delete:)) {
                canPerform = YES;
            }
        } else {
            if ( action == @selector(select:) || action == @selector(selectAll:) ||
                action == @selector(paste:)) {
                canPerform = YES;
            }
        }
    }
    
    ZNGLogVerbose(@"Returning %@ for %@ %@", canPerform ? @"YES" : @"NO", NSStringFromSelector(_cmd), NSStringFromSelector(action));
    
    return canPerform;
}

@end
