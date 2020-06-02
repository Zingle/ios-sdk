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
{
    UIButton * rightButton;
}

@dynamic textView;

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGConversationToolbarContentView class]];
    UIColor * buttonColor = [UIColor colorNamed:@"ZNGToolbarButton" inBundle:bundle compatibleWithTraitCollection:nil];
    self.messageModeButton.tintColor = buttonColor;
    self.templateButton.tintColor = buttonColor;
    self.customFieldButton.tintColor = buttonColor;
    self.automationButton.tintColor = buttonColor;
    self.imageButton.tintColor = buttonColor;
    self.noteButton.tintColor = buttonColor;
    
    if (@available(iOS 13.0, *)) {
        self.textView.backgroundColor = [UIColor systemBackgroundColor];
    }
}

- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (previousTraitCollection.verticalSizeClass != self.traitCollection.verticalSizeClass) {
        // Disable auto correction on our text field in vertically compact orientations to
        //  hide the Siri suggestions toolbar in our already cramped space
        BOOL hideSuggestionToolbar = self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
        self.textView.autocorrectionType = (hideSuggestionToolbar) ? UITextAutocorrectionTypeNo : UITextAutocorrectionTypeYes;
        
        if (self.textView.isFirstResponder) {
            [self.textView resignFirstResponder];
            [self.textView becomeFirstResponder];
        }
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

// Override JSQMessages's right bar button setting/getting to avoid its overly strict constraints when setting
- (void)setRightBarButtonItem:(UIButton *)newRightButton
{
    if (rightButton) {
        [rightButton removeFromSuperview];
    }

    if (!newRightButton) {
        rightButton = nil;
        self.rightBarButtonItemWidth = 0.0f;
        self.rightBarButtonContainerView.hidden = YES;
        return;
    }
    
    if (CGRectEqualToRect(newRightButton.frame, CGRectZero)) {
        newRightButton.frame = self.rightBarButtonContainerView.bounds;
    }

    self.rightBarButtonContainerView.hidden = NO;
    self.rightBarButtonItemWidth = CGRectGetWidth(newRightButton.frame);

    [newRightButton setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.rightBarButtonContainerView addSubview:newRightButton];
    NSLayoutConstraint * centerY = [NSLayoutConstraint constraintWithItem:newRightButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.rightBarButtonContainerView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    NSLayoutConstraint * right = [NSLayoutConstraint constraintWithItem:newRightButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.rightBarButtonContainerView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
    [self.rightBarButtonContainerView addConstraints:@[centerY, right]];
    [self setNeedsUpdateConstraints];

    rightButton = newRightButton;
}

- (UIButton *)rightBarButtonItem
{
    return rightButton;
}

@end
