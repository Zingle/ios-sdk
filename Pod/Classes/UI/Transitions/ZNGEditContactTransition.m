//
//  ZNGEditContactTransition.m
//  ZingleSDK
//
//  Created by Jason Neel on 2/5/18.
//

#import "ZNGEditContactTransition.h"
#import "ZNGContactEditViewController.h"
#import "ZNGServiceToContactViewController.h"
#import "UIButton+VisualCopy.h"
#import "UILabel+SubstringRect.h"
#import "UIViewController+ChildViewControllerOfType.h"

@import SBObjectiveCWrapper;

@implementation ZNGEditContactTransition

+ (NSTimeInterval)duration
{
    return 0.5;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return [[self class] duration];
}

- (void) animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView * container = transitionContext.containerView;
    UIViewController * fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    ZNGContactEditViewController * toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toViewController];
    ZNGServiceToContactViewController * conversationViewController = [fromViewController childViewControllerOfType:[ZNGServiceToContactViewController class]];
    
    // Force a layout of the destination view to force the safe area to be calculated
    toViewController.view.frame = toViewFinalFrame;
    [container addSubview:toViewController.view];
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
    CGRect destinationTitleFrame = toViewController.titleLabel.frame;
    UILabel * animatingTitle = [[UILabel alloc] initWithFrame:destinationTitleFrame];
    animatingTitle.font = toViewController.titleLabel.font;
    animatingTitle.textColor = toViewController.titleLabel.textColor;
    animatingTitle.text = toViewController.titleLabel.text;
    UILabel * oldColorAnimatingTitle = [[UILabel alloc] initWithFrame:animatingTitle.frame];
    oldColorAnimatingTitle.font = animatingTitle.font;
    oldColorAnimatingTitle.textColor = animatingTitle.textColor;  // Color will be set properly below
    oldColorAnimatingTitle.text = animatingTitle.text;
    
    UILabel * animatingNameLabel = nil;
    CGRect animatingNameFinalFrame = CGRectZero;
    
    // Find the location of the contact's name in our old header
    UILabel * fromTitleLabel = (UILabel *)conversationViewController.navigationItem.titleView;
    
    if ([fromTitleLabel isKindOfClass:[UILabel class]]) {
        CGRect bounds = [fromTitleLabel boundingRectForFirstLine];
        oldColorAnimatingTitle.textColor = fromTitleLabel.textColor;
        
        if (!CGRectIsEmpty(bounds)) {            
            // Adjust the animating title so it begins overlapping the contact name on the previous view
            CGRect fromTitleFrame = [fromTitleLabel convertRect:bounds toView:fromViewController.view];
            animatingTitle.frame = fromTitleFrame;
            oldColorAnimatingTitle.frame = animatingTitle.frame;
        }
        
        NSString * animatingName = [self assignmentStringToAnimateFromLabel:fromTitleLabel];
        
        if (animatingName != nil) {
            // Hide the name
            conversationViewController.hideContactName = YES;
            
            CGRect animatingNameStartBounds = [self frameForSubstring:animatingName withinLabel:fromTitleLabel];
            CGRect animatingNameStartFrame = [fromTitleLabel convertRect:animatingNameStartBounds toView:fromViewController.view];
            
            if (!CGRectIsEmpty(animatingNameStartFrame) && (toViewController.assignmentLabel != nil)) {
                CGFloat startingPointSize = [fromTitleLabel fontSizeOfSubstring:animatingName];
                CGFloat startingScale = startingPointSize / toViewController.assignmentLabel.font.pointSize;
                
                // Adjust starting frame for scale
                CGPoint animatingNameStartCenter = CGPointMake(CGRectGetMidX(animatingNameStartFrame), CGRectGetMidY(animatingNameStartFrame));
                animatingNameStartFrame = CGRectMake(0.0, 0.0, animatingNameStartFrame.size.width / startingScale, animatingNameStartFrame.size.width / startingScale);
                
                CGRect destinationBounds = [toViewController.assignmentLabel boundingRectForFirstLine];
                animatingNameFinalFrame = [toViewController.assignmentLabel convertRect:destinationBounds toView:toViewController.view];

                animatingNameLabel = [[UILabel alloc] initWithFrame:animatingNameStartFrame];
                animatingNameLabel.center = animatingNameStartCenter;
                animatingNameLabel.font = toViewController.assignmentLabel.font;
                animatingNameLabel.textColor = toViewController.assignmentLabel.textColor;
                animatingNameLabel.text = animatingName;
                animatingNameLabel.minimumScaleFactor = 0.2;
                animatingNameLabel.adjustsFontSizeToFitWidth = YES;
                animatingNameLabel.transform = CGAffineTransformMakeScale(startingScale, startingScale);
                animatingNameLabel.alpha = 0.58;
                
                // Hide the destination label
                toViewController.assignmentLabel.hidden = YES;
            }
        }
    } else {
        SBLogWarning(@"Unable to find conversation view's title UILabel to animate.  Sad.");
    }

    // Hide the title background that we have copied and will animate into place
    toViewController.titleContainer.backgroundColor = [UIColor clearColor];
    
    // Take snapshot of eventual view and hide it
    UIView * toSnapshot = [toViewController.view snapshotViewAfterScreenUpdates:YES];
    toViewController.view.hidden = YES;
    
    // Place the destination view off screen bottom
    toSnapshot.frame = CGRectMake(0.0, container.bounds.size.height, toViewFinalFrame.size.width, toViewFinalFrame.size.height);
    
    // Put everything in place in the correct order
    [container addSubview:toSnapshot];
    [container addSubview:animatingHeader];
    [animatingHeader addSubview:cancelButton];
    [animatingHeader addSubview:saveButton];
    [container addSubview:animatingTitle];
    [container addSubview:oldColorAnimatingTitle];
    
    if (animatingNameLabel != nil) {
        [container addSubview:animatingNameLabel];
    }
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    // Hide the title label a bit faster
    [UIView animateWithDuration:duration * 0.3 animations:^{
        fromTitleLabel.alpha = 0.0;
    }];
    
    // Let the animations begin
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        // Lower the header background into place
        animatingHeader.frame = headerFrame;
        cancelButton.alpha = 1.0;
        saveButton.alpha = 1.0;
        
        // Move the title precisely into place
        animatingTitle.frame = destinationTitleFrame;
        oldColorAnimatingTitle.frame = destinationTitleFrame;
        oldColorAnimatingTitle.alpha = 0.0;
        
        animatingNameLabel.alpha = 1.0;
        animatingNameLabel.transform = CGAffineTransformIdentity;
        animatingNameLabel.frame = animatingNameFinalFrame;
        
        // Bring the view up into the frame
        toSnapshot.frame = toViewFinalFrame;
    } completion:^(BOOL finished) {
        // Restore any text that we hid above
        toViewController.assignmentLabel.hidden = NO;
        fromTitleLabel.alpha = 1.0;
        conversationViewController.hideContactName = NO;
        
        // Restore the header color and button visibility
        toViewController.titleContainer.backgroundColor = headerColor;
        toViewController.cancelButton.hidden = NO;
        toViewController.saveButton.hidden = NO;
        
        conversationViewController.navigationItem.titleView.hidden = NO;
        
        toViewController.view.hidden = NO;
        [toSnapshot removeFromSuperview];
        [animatingHeader removeFromSuperview];
        [animatingTitle removeFromSuperview];
        [oldColorAnimatingTitle removeFromSuperview];
        [animatingNameLabel removeFromSuperview];
        
        [transitionContext completeTransition:YES];
    }];
}

- (NSString *) assignmentStringToAnimateFromLabel:(UILabel *)label
{
    NSRange unassignedRange = [label.text rangeOfString:@"unassigned" options:NSCaseInsensitiveSearch];
    NSRange assignedToRange = [label.text rangeOfString:@"assigned to " options:NSCaseInsensitiveSearch];
    
    if (unassignedRange.location != NSNotFound) {
        return [label.text substringWithRange:unassignedRange];
    } else if ((assignedToRange.location != NSNotFound) && ([label.text length] > (assignedToRange.location + assignedToRange.length))) {
        NSRange nameRange = NSMakeRange(assignedToRange.location + assignedToRange.length, [label.text length] - assignedToRange.location - assignedToRange.length);
        return [label.text substringWithRange:nameRange];
    }
    
    return nil;
}

- (CGRect) frameForSubstring:(NSString *)substring withinLabel:(UILabel *)label
{
    NSRange animatingTextRange = [label.text rangeOfString:substring];
    return [label boundingRectForTextRange:animatingTextRange];
}

@end
