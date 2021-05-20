//
//  ZNGServiceConversationToolbarContentView.m
//  Pods
//
//  Created by Jason Neel on 6/21/17.
//
//

#import "ZNGServiceConversationToolbarContentView.h"

@implementation ZNGServiceConversationToolbarContentView
{
    NSArray<NSLayoutConstraint *> * expandedButtonsConstraints;
    NSArray<NSLayoutConstraint *> * collapsedButtonsConstraints;
    
    BOOL buttonsAreCollapsed;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.revealButton.tintColor = self.templateButton.tintColor;
    
    self.revealButton.alpha = 0.0;
    
    NSDictionary * views = @{
                             @"templateButton": self.templateButton,
                             @"automationButton": self.automationButton,
                             @"imageButton": self.imageButton,
                             @"noteButton": self.noteButton,
                             @"revealButton": self.revealButton,
                             @"textView": self.textView
                             };
    
    
    NSString * expandedVisualFormat = @"H:[templateButton]-(16)-[automationButton]-(17)-[imageButton]-(22@750)-[noteButton]-(22)-[textView]";
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
    expandedButtonsConstraints = [expandedVisibleButtonConstraints arrayByAddingObject:[self constraintForSubview:self.templateButton withDistanceToLeftEdgeOfSafeArea:14.0]];
    
    [self addConstraints:expandedButtonsConstraints];
    
    
    NSString * collapsedButtonsFormat = @"H:[templateButton]-(16)-[automationButton]-(17)-[imageButton]-(22@750)-[noteButton]";
    
    NSArray<NSLayoutConstraint *> * buttonSpacingConstraints = [NSLayoutConstraint constraintsWithVisualFormat:collapsedButtonsFormat
                                                                                                       options:0
                                                                                                       metrics:0
                                                                                                         views:views];
    
    NSLayoutConstraint * buttonsOffScreenConstraint = [NSLayoutConstraint constraintWithItem:self.noteButton
                                                                                   attribute:NSLayoutAttributeRight
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:self
                                                                                   attribute:NSLayoutAttributeLeft
                                                                                  multiplier:1.0
                                                                                    constant:-6.0];
    
    NSString * revealButtonFormat = @"H:[revealButton]-(17)-[textView]";
    NSArray<NSLayoutConstraint *> * revealButtonConstraints = [NSLayoutConstraint constraintsWithVisualFormat:revealButtonFormat
                                                                                                      options:0
                                                                                                      metrics:0
                                                                                                        views:views];
    
    NSMutableArray<NSLayoutConstraint *> * collapsedConstraints = [buttonSpacingConstraints mutableCopy];
    [collapsedConstraints addObject:buttonsOffScreenConstraint];
    [collapsedConstraints addObjectsFromArray:revealButtonConstraints];
    [collapsedConstraints addObject:[self constraintForSubview:self.revealButton withDistanceToLeftEdgeOfSafeArea:17.0]];
    
    collapsedButtonsConstraints = collapsedConstraints;
}

/**
 *  Pre-iOS 11.0, this returns a constraint to the left edge of the view.  In iOS 11+, this returns a constraint to the left edge
 *   of the safe area.
 */
- (NSLayoutConstraint *) constraintForSubview:(UIView *)subview withDistanceToLeftEdgeOfSafeArea:(CGFloat)dx
{
    id safeArea;
    
    if (@available(iOS 11.0, *)) {
        safeArea = self.safeAreaLayoutGuide;
    } else {
        safeArea = self;
    }
    
    return [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:safeArea attribute:NSLayoutAttributeLeft multiplier:1.0 constant:dx];
}

- (void) enableOrDisableAllEditingButtons:(BOOL)enabled
{
    [super enableOrDisableAllEditingButtons:enabled];
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
    
    NSTimeInterval duration = animated ? 0.4 : 0.0;
    
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.0 options:0 animations:^{
        self.revealButton.alpha = 1.0;
        [self layoutIfNeeded];
    } completion:nil];
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
    
    NSTimeInterval duration = animated ? 0.4 : 0.0;
    
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.0 options:0 animations:^{
        self.revealButton.alpha = 0.0;
        [self layoutIfNeeded];
    } completion:nil];
}

@end
