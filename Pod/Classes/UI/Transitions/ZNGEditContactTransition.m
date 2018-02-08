//
//  ZNGEditContactTransition.m
//  ZingleSDK
//
//  Created by Jason Neel on 2/5/18.
//

#import "ZNGEditContactTransition.h"
#import "ZNGLogging.h"
#import "ZNGContactEditViewController.h"
#import "ZNGServiceToContactViewController.h"
#import "UILabel+SubstringRect.h"

static const int zngLogLevel = ZNGLogLevelInfo;

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
    return 0.5;
}

- (void) animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView * container = transitionContext.containerView;
    UISplitViewController * fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UITabBarController * tabController = [fromViewController.viewControllers lastObject];
    UINavigationController * navController = [tabController selectedViewController];
    ZNGContactEditViewController * toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toViewController];
    ZNGServiceToContactViewController * conversationViewController = nil;
    
    for (UIViewController * vc in navController.viewControllers) {
        if ([vc isKindOfClass:[ZNGServiceToContactViewController class]]) {
            conversationViewController = (ZNGServiceToContactViewController *)vc;
            break;
        }
    }
    
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
    NSRange hiddenTitleRange = NSMakeRange(NSNotFound, 0);
    __block UIColor * hiddenTitleColor = nil;
    
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
            hiddenTitleRange = [fromTitleLabel.text rangeOfString:animatingName];
            NSMutableAttributedString * attributedTitleText = [fromTitleLabel.attributedText mutableCopy];
            [attributedTitleText enumerateAttribute:NSForegroundColorAttributeName inRange:hiddenTitleRange options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
                hiddenTitleColor = value;
                *stop = YES;
            }];
            [attributedTitleText addAttribute:NSForegroundColorAttributeName value:[UIColor clearColor] range:hiddenTitleRange];
            fromTitleLabel.attributedText = attributedTitleText;
            
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
                
                // Shimmy right for margins
                animatingNameFinalFrame = CGRectOffset(animatingNameFinalFrame, toViewController.assignmentLabelCellLeftMargin, 0.0);

                animatingNameLabel = [[UILabel alloc] initWithFrame:animatingNameStartFrame];
                animatingNameLabel.center = animatingNameStartCenter;
                animatingNameLabel.font = toViewController.assignmentLabel.font;
                animatingNameLabel.textColor = toViewController.assignmentLabel.textColor;
                animatingNameLabel.text = animatingName;
                animatingNameLabel.minimumScaleFactor = 0.2;
                animatingNameLabel.adjustsFontSizeToFitWidth = YES;
                animatingNameLabel.transform = CGAffineTransformMakeScale(startingScale, startingScale);
                animatingNameLabel.alpha = 0.5;
                
                // Hide the name that we are animating and the destination label
                toViewController.assignmentLabel.hidden = YES;
                [attributedTitleText addAttribute:NSForegroundColorAttributeName value:[UIColor clearColor] range:hiddenTitleRange];
                fromTitleLabel.attributedText = attributedTitleText;
            }
        }
    } else {
        ZNGLogWarn(@"Unable to find conversation view's title UILabel to animate.  Sad.");
    }

    
    // Hide some things from both source and destination that we are animating
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
        NSMutableAttributedString * text = [fromTitleLabel.attributedText mutableCopy];
        [text enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, [text length]) options:0 usingBlock:^(UIColor * _Nullable value, NSRange range, BOOL * _Nonnull stop) {
            if ([value isEqual:[UIColor clearColor]]) {
                [text removeAttribute:NSForegroundColorAttributeName range:range];
            }
        }];
        if (hiddenTitleColor != nil) {
            [text addAttribute:NSForegroundColorAttributeName value:hiddenTitleColor range:hiddenTitleRange];
        }
        fromTitleLabel.attributedText = text;
        
        // Restore the header color and button visibility
        toViewController.titleContainer.backgroundColor = headerColor;
        toViewController.cancelButton.hidden = NO;
        toViewController.saveButton.hidden = NO;
        
        conversationViewController.navigationItem.titleView.hidden = NO;
        
        [container addSubview:toViewController.view];
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
