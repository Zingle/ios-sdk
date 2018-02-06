//
//  ZNGEditContactTransition.m
//  ZingleSDK
//
//  Created by Jason Neel on 2/5/18.
//

#import "ZNGEditContactTransition.h"
#import "ZNGContactEditViewController.h"
#import "ZNGServiceToContactViewController.h"

@interface UIButton (VisualCopy)
- (UIButton *)nonInteractiveCopy;
@end

@implementation UIButton (VisualCopy)

- (UIButton *)nonInteractiveCopy
{
    UIButton * button = [[UIButton alloc] initWithFrame:self.frame];
    [button setTitle:[self titleForState:UIControlStateNormal] forState:UIControlStateNormal];
    [button setAttributedTitle:[self attributedTitleForState:UIControlStateNormal] forState:UIControlStateNormal];
    button.titleLabel.font = self.titleLabel.font;
    button.titleLabel.textColor = self.titleLabel.textColor;
    button.userInteractionEnabled = NO;
    
    return button;
}

@end

@implementation ZNGEditContactTransition

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.35;
}

- (void) animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView * container = transitionContext.containerView;
    ZNGServiceToContactViewController * fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    ZNGContactEditViewController * toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toViewController];
    
    // Force a layout of the destination view to force the safe area to be calculated
    [toViewController.view setNeedsLayout];
    [toViewController.view layoutIfNeeded];
    
    // Create our animating version of the header background, just above the display area
    CGRect headerFrame = toViewController.titleContainer.frame;
    UIView * animatingHeader = [[UIView alloc] initWithFrame:CGRectMake(0.0, -headerFrame.size.height, headerFrame.size.width, headerFrame.size.height)];
    UIColor * headerColor = toViewController.titleContainer.backgroundColor;
    animatingHeader.backgroundColor = headerColor;
    
    // Make copies of the two navigation buttons to place above our animating header
    UIButton * cancelButton = [toViewController.cancelButton nonInteractiveCopy];
    cancelButton.alpha = 0.0;
    UIButton * saveButton = [toViewController.saveButton nonInteractiveCopy];
    saveButton.alpha = 0.0;
    
    // Hide the original buttons
    toViewController.cancelButton.hidden = YES;
    toViewController.saveButton.hidden = YES;
    
    // Copy the title.
    // Note that its coordinates are relative to the header view, but the header is at 0.0, 0.0, so we
    //  do not strictly need to convert these coordinates.
    UILabel * animatingTitle = [[UILabel alloc] initWithFrame:toViewController.titleLabel.frame];
    animatingTitle.font = toViewController.titleLabel.font;
    animatingTitle.textColor = toViewController.titleLabel.textColor;
    animatingTitle.text = toViewController.titleLabel.text;
    
    // Make the existing header container uncolored during our animation
    toViewController.titleContainer.backgroundColor = [UIColor clearColor];
    
    // Take snapshot of eventual view
    UIView * toSnapshot = [toViewController.view snapshotViewAfterScreenUpdates:YES];
    
    // Place the destination view off screen bottom
    toSnapshot.frame = CGRectMake(0.0, container.bounds.size.height, toViewFinalFrame.size.width, toViewFinalFrame.size.height);
    
    // Put everything in place in the correct order
    [container addSubview:toSnapshot];
    [container addSubview:animatingHeader];
    [animatingHeader addSubview:cancelButton];
    [animatingHeader addSubview:saveButton];
    [container addSubview:animatingTitle];
    
    // Let the animations begin
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        // Lower the header background into place
        animatingHeader.frame = headerFrame;
        cancelButton.alpha = 1.0;
        saveButton.alpha = 1.0;
        
        // Bring the view up into the frame
        toSnapshot.frame = toViewFinalFrame;
    } completion:^(BOOL finished) {
        // Restore the header color and button visibility
        toViewController.titleContainer.backgroundColor = headerColor;
        toViewController.cancelButton.hidden = NO;
        toViewController.saveButton.hidden = NO;
        
        [container addSubview:toViewController.view];
        [toSnapshot removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
}

@end
