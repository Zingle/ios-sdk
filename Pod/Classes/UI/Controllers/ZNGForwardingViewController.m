//
//  ZNGForwardingViewController.m
//  Pods
//
//  Created by Jason Neel on 12/1/16.
//
//

#import "ZNGForwardingViewController.h"
#import "ZNGForwardingInputToolbar.h"
#import "ZNGMessage.h"

#define kToolbarHeightKVOPath @"contentView.textView.contentSize"

@interface ZNGForwardingViewController ()

@end

@implementation ZNGForwardingViewController
{
    BOOL userHasInteracted; // Flag used to determine if we should confirm before dismissing
    
    CGFloat initialToolbarHeight;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    initialToolbarHeight = self.toolbarHeightConstraint.constant;
    
    self.inputToolbar.contentView.textView.text = self.message.body;
    
    [self.inputToolbar addObserver:self forKeyPath:kToolbarHeightKVOPath options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardAppearingOrDisappearing:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardAppearingOrDisappearing:) name:UIKeyboardWillHideNotification object:nil];
}

- (void) dealloc
{
    [self.inputToolbar removeObserver:self forKeyPath:kToolbarHeightKVOPath];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Toolbar height
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:kToolbarHeightKVOPath]) {
        NSValue * oldContentSizeValue = change[NSKeyValueChangeOldKey];
        NSValue * newContentSizeValue = change[NSKeyValueChangeNewKey];
        
        if ((![oldContentSizeValue isKindOfClass:[NSValue class]]) || (![newContentSizeValue isKindOfClass:[NSValue class]])) {
            // This is probably initialization with no previous value
            return;
        }
        
        [self resizeToolbarWithDY:[newContentSizeValue CGSizeValue].height - [oldContentSizeValue CGSizeValue].height];
    }
}

- (void) resizeToolbarWithDY:(CGFloat)dy
{
    CGFloat targetHeight = self.toolbarHeightConstraint.constant + dy;
    
    // Are we getting too tall?
    if ((dy > 0.0) && (targetHeight >= 400.0)) {
        return;
    }
    
    // Too small?
    if ((dy < 0.0) && (targetHeight < initialToolbarHeight)) {
        targetHeight = initialToolbarHeight;
    }
    
    self.toolbarHeightConstraint.constant = targetHeight;
    [self.view setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];
}

#pragma mark - Keyboard handling
- (void) keyboardAppearingOrDisappearing:(NSNotification *)notification
{
    double duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardEndFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardLocalFrame = [self.view convertRect:keyboardEndFrame fromView:nil];
    CGFloat keyboardTop = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(keyboardLocalFrame);
    UIViewAnimationCurve animationCurve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    self.toolbarBottomSpaceConstraint.constant = keyboardTop;
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:duration delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState|(animationCurve << 16)) animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

/*
 func keyboardAppearingOrDisappearing(notification: NSNotification) {
 let duration = (notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
 let keyboardEndFrame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
 let keyboardLocalFrame = view.convertRect(keyboardEndFrame, fromView: view.window)
 let keyboardTop = CGRectGetMaxY(view.bounds) - CGRectGetMinY(keyboardLocalFrame)
 
 let rawAnimationCurve = (notification.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedIntValue << 16
 let animationCurve = UIViewAnimationOptions(rawValue: UInt(rawAnimationCurve))
 
 inputToolbarBottomSpaceConstraint.constant = keyboardTop
 view.setNeedsUpdateConstraints()
 
 UIView.animateWithDuration(duration, delay: 0.0, options: [.BeginFromCurrentState, animationCurve], animations: {
 self.view.layoutIfNeeded()
 }, completion: nil)
 }
 */

#pragma mark - Actions
- (IBAction) pressedCancel:(id)sender
{
    if (!userHasInteracted) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Cancel forwarding?" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction * leave = [UIAlertAction actionWithTitle:@"Discard" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        [alert addAction:leave];
        
        UIAlertAction * stay = [UIAlertAction actionWithTitle:@"Continue forwarding" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:stay];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
