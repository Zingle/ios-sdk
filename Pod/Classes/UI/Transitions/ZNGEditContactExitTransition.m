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
#import "ZNGServiceToContactViewController.h"
#import "NSAttributedString+GroupingSubstrings.h"
#import "UILabel+SubstringRect.h"
#import "UIViewController+ChildViewControllerOfType.h"

@import SBObjectiveCWrapper;

@implementation ZNGEditContactExitTransition

- (NSTimeInterval) transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return [ZNGEditContactTransition duration];
}

- (void) animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController * toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    ZNGServiceToContactViewController * conversationViewController = [toViewController childViewControllerOfType:[ZNGServiceToContactViewController class]];
    ZNGContactEditViewController * fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    // Add the destination view underneath all of our animating nonsense
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    [transitionContext.containerView addSubview:toViewController.view];
    
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
    
    // Create a contact name label to animate from the edit header to the conversation header
    UILabel * conversationTitleLabel = (UILabel *)conversationViewController.navigationItem.titleView;
    CGRect nameDestinationFrame = CGRectNull;
    UILabel * blueAnimatingNameLabel = nil;
    UILabel * whiteAnimatingNameLabel = nil;
    __block NSRange nameRange = NSMakeRange(NSNotFound, 0);
    
    if ([conversationTitleLabel isKindOfClass:[UILabel class]]) {
        NSString * contactName = [[conversationTitleLabel.attributedText substringsByLineAndAttributes] firstObject];
        nameRange = [conversationTitleLabel.text rangeOfString:contactName];
        CGRect nameBounds = [conversationTitleLabel boundingRectForTextRange:nameRange];
        
        if (!CGRectIsEmpty(nameBounds)) {
            nameDestinationFrame = [conversationTitleLabel convertRect:nameBounds toView:transitionContext.containerView];
            CGRect nameStartFrame = [fromViewController.titleLabel convertRect:fromViewController.titleLabel.bounds toView:transitionContext.containerView];
            
            blueAnimatingNameLabel = [[UILabel alloc] initWithFrame:nameStartFrame];
            blueAnimatingNameLabel.text = contactName;
            blueAnimatingNameLabel.textColor = conversationTitleLabel.textColor;
            blueAnimatingNameLabel.font = conversationTitleLabel.font;
            whiteAnimatingNameLabel = [[UILabel alloc] initWithFrame:nameStartFrame];
            whiteAnimatingNameLabel.text = blueAnimatingNameLabel.text;
            whiteAnimatingNameLabel.textColor = fromViewController.titleLabel.textColor;
            whiteAnimatingNameLabel.font = blueAnimatingNameLabel.font;
            
            [transitionContext.containerView addSubview:blueAnimatingNameLabel];
            [transitionContext.containerView addSubview:whiteAnimatingNameLabel];
            
            // Hide the original name while we animate this name up
            NSMutableAttributedString * mutableName = [conversationTitleLabel.attributedText mutableCopy];
            [mutableName addAttribute:NSForegroundColorAttributeName value:[UIColor clearColor] range:nameRange];
            conversationTitleLabel.attributedText = mutableName;
        }
    } else {
        SBLogWarning(@"Unable to find title label in conversation view when exiting contact edit view.  The name will not animate.");
    }
    
    // Remove the actual from view
    [fromViewController.view removeFromSuperview];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        blueAnimatingNameLabel.frame = nameDestinationFrame;
        whiteAnimatingNameLabel.frame = nameDestinationFrame;
        whiteAnimatingNameLabel.alpha = 0.0;
        cancelButton.alpha = 0.0;
        saveButton.alpha = 0.0;
        editSnapshot.frame = snapshotOffScreenFrame;
        animatingBlueness.frame = blueHeaderOffScreenFrame;
    } completion:^(BOOL finished) {
        // Remove animating stuffs
        [blueAnimatingNameLabel removeFromSuperview];
        [whiteAnimatingNameLabel removeFromSuperview];
        [editSnapshot removeFromSuperview];
        [animatingBlueness removeFromSuperview];
        
        // Unhide contact name
        NSMutableAttributedString * mutableName = [conversationTitleLabel.attributedText mutableCopy];
        NSString * contactName = [[conversationTitleLabel.attributedText substringsByLineAndAttributes] firstObject];
        
        // Re-calculate name range.  If a contact's name is being edited, the name will have changed between when we started this transition and now.  Scary.
        nameRange = [mutableName.string rangeOfString:contactName];
        [mutableName removeAttribute:NSForegroundColorAttributeName range:nameRange];
        conversationTitleLabel.attributedText = mutableName;
        
        [transitionContext completeTransition:YES];
    }];
}

@end
