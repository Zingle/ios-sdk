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

@implementation ZNGConversationToolbarContentView
{
    NSArray<NSLayoutConstraint *> * expandedButtonsConstraints;
    NSArray<NSLayoutConstraint *> * collapsedButtonsConstraints;
    
    BOOL buttonsAreCollapsed;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    UIColor * gray = [UIColor zng_gray];
    self.templateButton.tintColor = gray;
    self.customFieldButton.tintColor = gray;
    self.automationButton.tintColor = gray;
    self.imageButton.tintColor = gray;
    self.noteButton.tintColor = gray;
    self.revealButton.tintColor = gray;
    
    self.revealButton.alpha = 0.0;
    
    NSDictionary * views = @{
                             @"templateButton": self.templateButton,
                             @"automationButton": self.automationButton,
                             @"imageButton": self.imageButton,
                             @"noteButton": self.noteButton,
                             @"revealButton": self.revealButton,
                             @"textView": self.textView,
                             @"superview": self
                             };
    
    
    NSString * expandedVisualFormat = @"H:|-(8)-[templateButton]-(4)-[automationButton]-(8)-[imageButton]-(9)-[noteButton]-(8)-[textView]";
    NSArray<NSLayoutConstraint *> * expandedVisibleButtonConstraints = [NSLayoutConstraint constraintsWithVisualFormat:expandedVisualFormat
                                                                                                               options:0
                                                                                                               metrics:0
                                                                                                                 views:views];
    
    NSLayoutConstraint * expandButtonUnderTextFieldConstraint = [NSLayoutConstraint constraintWithItem:self.revealButton
                                                                                             attribute:NSLayoutAttributeLeft
                                                                                             relatedBy:NSLayoutRelationEqual
                                                                                                toItem:self.textView
                                                                                             attribute:NSLayoutAttributeLeft
                                                                                            multiplier:1.0
                                                                                              constant:6.0];
    
    expandedButtonsConstraints = [expandedVisibleButtonConstraints arrayByAddingObject:expandButtonUnderTextFieldConstraint];
    
    [self addConstraints:expandedButtonsConstraints];
    
    
    NSString * collapsedButtonsFormat = @"H:[templateButton]-(2)-[automationButton]-(4)-[imageButton]-(11)-[noteButton]";

    NSArray<NSLayoutConstraint *> * buttonSpacingConstraints = [NSLayoutConstraint constraintsWithVisualFormat:collapsedButtonsFormat
                                                                                                       options:0
                                                                                                       metrics:0
                                                                                                         views:views];
    
    NSLayoutConstraint * buttonsOffScreenConstraint = [NSLayoutConstraint constraintWithItem:self.noteButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-6.0];
    
    NSString * revealButtonFormat = @"H:|-(10)-[revealButton]-(10)-[textView]";
    NSArray<NSLayoutConstraint *> * revealButtonConstraints = [NSLayoutConstraint constraintsWithVisualFormat:revealButtonFormat options:0 metrics:0 views:views];
    
    NSMutableArray<NSLayoutConstraint *> * collapsedConstraints = [buttonSpacingConstraints mutableCopy];
    [collapsedConstraints addObject:buttonsOffScreenConstraint];
    [collapsedConstraints addObjectsFromArray:revealButtonConstraints];
    
    collapsedButtonsConstraints = collapsedConstraints;
}

- (void) enableOrDisableAllEditingButtons:(BOOL)enabled
{
    self.templateButton.enabled = enabled;
    self.customFieldButton.enabled = enabled;
    self.automationButton.enabled = enabled;
    self.imageButton.enabled = enabled;
    self.noteButton.enabled = enabled;
    self.revealButton.enabled = enabled;
}

- (void) collapseButtons:(BOOL)animated
{
    if (buttonsAreCollapsed) {
        return;
    }
    
    buttonsAreCollapsed = YES;
    
    [self removeConstraints:expandedButtonsConstraints];
    [self addConstraints:collapsedButtonsConstraints];
    
    [self setNeedsUpdateConstraints];
    
    if (animated) {
        [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.0 options:0 animations:^{
            self.revealButton.alpha = 1.0;
            [self layoutIfNeeded];
        } completion:nil];
    } else {
        [self layoutIfNeeded];
    }
}

- (void) expandButtons:(BOOL)animated
{
    if (!buttonsAreCollapsed) {
        return;
    }
    
    buttonsAreCollapsed = NO;
    
    [self removeConstraints:collapsedButtonsConstraints];
    [self addConstraints:expandedButtonsConstraints];
    
    [self setNeedsUpdateConstraints];
    
    if (animated) {
        [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.0 options:0 animations:^{
            self.revealButton.alpha = 0.0;
            [self layoutIfNeeded];
        } completion:nil];
    } else {
        [self layoutIfNeeded];
    }
}

@end
