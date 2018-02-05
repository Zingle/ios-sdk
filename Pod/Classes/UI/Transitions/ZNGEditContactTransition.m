//
//  ZNGEditContactTransition.m
//  ZingleSDK
//
//  Created by Jason Neel on 2/5/18.
//

#import "ZNGEditContactTransition.h"

@implementation ZNGEditContactTransition

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.35;
}

- (void) animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView * container = transitionContext.containerView;
    UIViewController * fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController * toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toViewController];
    
    // Take snapshot of eventual view
    UIView * toSnapshot = [toViewController.view snapshotViewAfterScreenUpdates:YES];
    
    // Shimmy it into place
    toSnapshot.frame = CGRectMake(0.0, container.bounds.size.height, toViewFinalFrame.size.width, toViewFinalFrame.size.height);
    [container addSubview:toSnapshot];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        toSnapshot.frame = toViewFinalFrame;
    } completion:^(BOOL finished) {
        [container addSubview:toViewController.view];
        [toSnapshot removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
}

@end
