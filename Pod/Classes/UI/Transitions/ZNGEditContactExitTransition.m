//
//  ZNGEditContactExitTransition.m
//  ZingleSDK
//
//  Created by Jason Neel on 2/8/18.
//

#import "ZNGEditContactExitTransition.h"
#import "ZNGEditContactTransition.h"
#import "ZNGContactEditViewController.h"
#import "UIButton+VisualCopy.h"

@implementation ZNGEditContactExitTransition

- (NSTimeInterval) transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return [ZNGEditContactTransition duration];
}

- (void) animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UISplitViewController * toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    ZNGContactEditViewController * fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    // Add the destination view underneath all of our animating nonsense
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    [transitionContext.containerView addSubview:toViewController.view];
    
    // Calculate the position of the contact name in the conversation title view
    
    // Create a blue header, cancel button, and save button copy to animate off screen top
    CGRect blueHeaderFrame = CGRectMake(0.0, 0.0, fromViewController.titleContainer.frame.size.width, fromViewController.titleContainer.frame.size.height);
    CGRect blueHeaderOffScreenFrame = CGRectOffset(blueHeaderFrame, 0.0, -blueHeaderFrame.size.height);
    UIView * animatingBlueness = [[UIView alloc] initWithFrame:blueHeaderFrame];
    animatingBlueness.backgroundColor = fromViewController.titleContainer.backgroundColor;
    [transitionContext.containerView addSubview:animatingBlueness];
    
    UIButton * cancelButton = [fromViewController.cancelButton nonInteractiveCopy];
    UIButton * saveButton = [fromViewController.saveButton nonInteractiveCopy];
    [animatingBlueness addSubview:cancelButton];
    [animatingBlueness addSubview:saveButton];
    
    // Create a contact name label to animate from the edit header to the conversation header
    
    // Take a snapshot of the dismissing view, cropped below the header
    UIView * editSnapshot = [fromViewController.view snapshotViewAfterScreenUpdates:NO];
    CAShapeLayer * snapshotMask = [[CAShapeLayer alloc] init];
    CGPathRef snapshotMaskPath = CGPathCreateWithRect(CGRectMake(0.0,
                                                                 blueHeaderFrame.size.height,
                                                                 transitionContext.containerView.bounds.size.width,
                                                                 transitionContext.containerView.bounds.size.height - blueHeaderFrame.size.height), NULL);
    snapshotMask.path = snapshotMaskPath;
    editSnapshot.layer.mask = snapshotMask;
    [transitionContext.containerView addSubview:editSnapshot];
    CGRect snapshotOffScreenFrame = CGRectOffset(editSnapshot.frame, 0.0, transitionContext.containerView.bounds.size.height - blueHeaderFrame.size.height);
    
    // Remove the actual from view
    [fromViewController.view removeFromSuperview];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        cancelButton.alpha = 0.0;
        saveButton.alpha = 0.0;
        editSnapshot.frame = snapshotOffScreenFrame;
        animatingBlueness.frame = blueHeaderOffScreenFrame;
    } completion:^(BOOL finished) {
        [editSnapshot removeFromSuperview];
        [animatingBlueness removeFromSuperview];
        
        [transitionContext completeTransition:YES];
    }];
}

@end
