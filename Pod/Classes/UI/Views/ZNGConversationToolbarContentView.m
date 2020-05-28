//
//  ZNGConversationToolbarContentView.m
//  Pods
//
//  Created by Jason Neel on 7/18/16.
//
//

#import "ZNGConversationToolbarContentView.h"
#import "UIColor+ZingleSDK.h"
#import "UIFont+Lato.h"

@import SBObjectiveCWrapper;

@implementation ZNGConversationToolbarContentView

@dynamic textView;

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGConversationToolbarContentView class]];
    UIColor * buttonColor = [UIColor colorNamed:@"ZNGToolbarButton" inBundle:bundle compatibleWithTraitCollection:nil];
    self.templateButton.tintColor = buttonColor;
    self.customFieldButton.tintColor = buttonColor;
    self.automationButton.tintColor = buttonColor;
    self.imageButton.tintColor = buttonColor;
    self.noteButton.tintColor = buttonColor;
    
    if (@available(iOS 13.0, *)) {
        self.textView.backgroundColor = [UIColor systemBackgroundColor];
    }
}

- (void) enableOrDisableAllEditingButtons:(BOOL)enabled
{
    self.messageModeButton.enabled = enabled;
    self.templateButton.enabled = enabled;
    self.customFieldButton.enabled = enabled;
    self.automationButton.enabled = enabled;
    self.imageButton.enabled = enabled;
    self.noteButton.enabled = enabled;
}

- (void) enableButton:(nonnull UIButton *)button
{
    if (![self.buttonStackView.arrangedSubviews containsObject:button]) {
        SBLogError(@"enableButton: was called with a button that does not exist in our button list: %@", button);
        return;
    }
    
    button.hidden = NO;
}

- (void) disableButton:(nonnull UIButton *)button
{
    if (![self.buttonStackView.arrangedSubviews containsObject:button]) {
        SBLogError(@"disableButton: was called with a button that does not exist in our button list: %@", button);
        return;
    }
    
    button.hidden = YES;
}

@end
