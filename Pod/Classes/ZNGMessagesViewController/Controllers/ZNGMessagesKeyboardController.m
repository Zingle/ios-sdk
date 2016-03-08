
#import "ZNGMessagesKeyboardController.h"

#import "UIDevice+ZNGMessages.h"


NSString * const ZNGMessagesKeyboardControllerNotificationKeyboardDidChangeFrame = @"ZNGMessagesKeyboardControllerNotificationKeyboardDidChangeFrame";
NSString * const ZNGMessagesKeyboardControllerUserInfoKeyKeyboardDidChangeFrame = @"ZNGMessagesKeyboardControllerUserInfoKeyKeyboardDidChangeFrame";

static void * kZNGMessagesKeyboardControllerKeyValueObservingContext = &kZNGMessagesKeyboardControllerKeyValueObservingContext;

typedef void (^ZNGAnimationCompletionBlock)(BOOL finished);



@interface ZNGMessagesKeyboardController () <UIGestureRecognizerDelegate>

@property (assign, nonatomic) BOOL zng_isObserving;

@property (weak, nonatomic) UIView *keyboardView;

- (void)zng_registerForNotifications;
- (void)zng_unregisterForNotifications;

- (void)zng_didReceiveKeyboardDidShowNotification:(NSNotification *)notification;
- (void)zng_didReceiveKeyboardWillChangeFrameNotification:(NSNotification *)notification;
- (void)zng_didReceiveKeyboardDidChangeFrameNotification:(NSNotification *)notification;
- (void)zng_didReceiveKeyboardDidHideNotification:(NSNotification *)notification;
- (void)zng_handleKeyboardNotification:(NSNotification *)notification completion:(ZNGAnimationCompletionBlock)completion;

- (void)zng_setKeyboardViewHidden:(BOOL)hidden;
- (void)zng_notifyKeyboardFrameNotificationForFrame:(CGRect)frame;
- (void)zng_resetKeyboardAndTextView;

- (void)zng_removeKeyboardFrameObserver;

- (void)zng_handlePanGestureRecognizer:(UIPanGestureRecognizer *)pan;

@end



@implementation ZNGMessagesKeyboardController

#pragma mark - Initialization

- (instancetype)initWithTextView:(UITextView *)textView
                     contextView:(UIView *)contextView
            panGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer
                        delegate:(id<ZNGMessagesKeyboardControllerDelegate>)delegate

{
    NSParameterAssert(textView != nil);
    NSParameterAssert(contextView != nil);
    NSParameterAssert(panGestureRecognizer != nil);

    self = [super init];
    if (self) {
        _textView = textView;
        _contextView = contextView;
        _panGestureRecognizer = panGestureRecognizer;
        _delegate = delegate;
        _zng_isObserving = NO;
    }
    return self;
}

- (void)dealloc
{
    [self zng_removeKeyboardFrameObserver];
    [self zng_unregisterForNotifications];
    _textView = nil;
    _contextView = nil;
    _panGestureRecognizer = nil;
    _delegate = nil;
    _keyboardView = nil;
}

#pragma mark - Setters

- (void)setKeyboardView:(UIView *)keyboardView
{
    if (_keyboardView) {
        [self zng_removeKeyboardFrameObserver];
    }

    _keyboardView = keyboardView;

    if (keyboardView && !_zng_isObserving) {
        [_keyboardView addObserver:self
                        forKeyPath:NSStringFromSelector(@selector(frame))
                           options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                           context:kZNGMessagesKeyboardControllerKeyValueObservingContext];

        _zng_isObserving = YES;
    }
}

#pragma mark - Getters

- (BOOL)keyboardIsVisible
{
    return self.keyboardView != nil;
}

- (CGRect)currentKeyboardFrame
{
    if (!self.keyboardIsVisible) {
        return CGRectNull;
    }

    return self.keyboardView.frame;
}

#pragma mark - Keyboard controller

- (void)beginListeningForKeyboard
{
    if (self.textView.inputAccessoryView == nil) {
        self.textView.inputAccessoryView = [[UIView alloc] init];
    }

    [self zng_registerForNotifications];
}

- (void)endListeningForKeyboard
{
    [self zng_unregisterForNotifications];

    [self zng_setKeyboardViewHidden:NO];
    self.keyboardView = nil;
}

#pragma mark - Notifications

- (void)zng_registerForNotifications
{
    [self zng_unregisterForNotifications];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(zng_didReceiveKeyboardDidShowNotification:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(zng_didReceiveKeyboardWillChangeFrameNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(zng_didReceiveKeyboardDidChangeFrameNotification:)
                                                 name:UIKeyboardDidChangeFrameNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(zng_didReceiveKeyboardDidHideNotification:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

- (void)zng_unregisterForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)zng_didReceiveKeyboardDidShowNotification:(NSNotification *)notification
{
    self.keyboardView = self.textView.inputAccessoryView.superview;
    [self zng_setKeyboardViewHidden:NO];

    [self zng_handleKeyboardNotification:notification completion:^(BOOL finished) {
        [self.panGestureRecognizer addTarget:self action:@selector(zng_handlePanGestureRecognizer:)];
    }];
}

- (void)zng_didReceiveKeyboardWillChangeFrameNotification:(NSNotification *)notification
{
    [self zng_handleKeyboardNotification:notification completion:nil];
}

- (void)zng_didReceiveKeyboardDidChangeFrameNotification:(NSNotification *)notification
{
    [self zng_setKeyboardViewHidden:NO];

    [self zng_handleKeyboardNotification:notification completion:nil];
}

- (void)zng_didReceiveKeyboardDidHideNotification:(NSNotification *)notification
{
    self.keyboardView = nil;

    [self zng_handleKeyboardNotification:notification completion:^(BOOL finished) {
        [self.panGestureRecognizer removeTarget:self action:NULL];
    }];
}

- (void)zng_handleKeyboardNotification:(NSNotification *)notification completion:(ZNGAnimationCompletionBlock)completion
{
    NSDictionary *userInfo = [notification userInfo];

    CGRect keyboardEndFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];

    if (CGRectIsNull(keyboardEndFrame)) {
        return;
    }

    UIViewAnimationCurve animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    NSInteger animationCurveOption = (animationCurve << 16);

    double animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    CGRect keyboardEndFrameConverted = [self.contextView convertRect:keyboardEndFrame fromView:nil];

    [UIView animateWithDuration:animationDuration
                          delay:0.0
                        options:animationCurveOption
                     animations:^{
                         [self zng_notifyKeyboardFrameNotificationForFrame:keyboardEndFrameConverted];
                     }
                     completion:^(BOOL finished) {
                         if (completion) {
                             completion(finished);
                         }
                     }];
}

#pragma mark - Utilities

- (void)zng_setKeyboardViewHidden:(BOOL)hidden
{
    self.keyboardView.hidden = hidden;
    self.keyboardView.userInteractionEnabled = !hidden;
}

- (void)zng_notifyKeyboardFrameNotificationForFrame:(CGRect)frame
{
    [self.delegate keyboardController:self keyboardDidChangeFrame:frame];

    [[NSNotificationCenter defaultCenter] postNotificationName:ZNGMessagesKeyboardControllerNotificationKeyboardDidChangeFrame
                                                        object:self
                                                      userInfo:@{ ZNGMessagesKeyboardControllerUserInfoKeyKeyboardDidChangeFrame : [NSValue valueWithCGRect:frame] }];
}

- (void)zng_resetKeyboardAndTextView
{
    [self zng_setKeyboardViewHidden:YES];
    [self zng_removeKeyboardFrameObserver];
    [self.textView resignFirstResponder];
}

#pragma mark - Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kZNGMessagesKeyboardControllerKeyValueObservingContext) {

        if (object == self.keyboardView && [keyPath isEqualToString:NSStringFromSelector(@selector(frame))]) {

            CGRect oldKeyboardFrame = [[change objectForKey:NSKeyValueChangeOldKey] CGRectValue];
            CGRect newKeyboardFrame = [[change objectForKey:NSKeyValueChangeNewKey] CGRectValue];

            if (CGRectEqualToRect(newKeyboardFrame, oldKeyboardFrame) || CGRectIsNull(newKeyboardFrame)) {
                return;
            }
            
            CGRect keyboardEndFrameConverted = [self.contextView convertRect:newKeyboardFrame
                                                                    fromView:self.keyboardView.superview];
            [self zng_notifyKeyboardFrameNotificationForFrame:keyboardEndFrameConverted];
        }
    }
}

- (void)zng_removeKeyboardFrameObserver
{
    if (!_zng_isObserving) {
        return;
    }

    @try {
        [_keyboardView removeObserver:self
                           forKeyPath:NSStringFromSelector(@selector(frame))
                              context:kZNGMessagesKeyboardControllerKeyValueObservingContext];
    }
    @catch (NSException * __unused exception) { }

    _zng_isObserving = NO;
}

#pragma mark - Pan gesture recognizer

- (void)zng_handlePanGestureRecognizer:(UIPanGestureRecognizer *)pan
{
    CGPoint touch = [pan locationInView:self.contextView.window];

    //  system keyboard is added to a new UIWindow, need to operate in window coordinates
    //  also, keyboard always slides from bottom of screen, not the bottom of a view
    CGFloat contextViewWindowHeight = CGRectGetHeight(self.contextView.window.frame);

    if ([UIDevice zng_isCurrentDeviceBeforeiOS8]) {
        //  handle iOS 7 bug when rotating to landscape
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            contextViewWindowHeight = CGRectGetWidth(self.contextView.window.frame);
        }
    }

    CGFloat keyboardViewHeight = CGRectGetHeight(self.keyboardView.frame);

    CGFloat dragThresholdY = (contextViewWindowHeight - keyboardViewHeight - self.keyboardTriggerPoint.y);

    CGRect newKeyboardViewFrame = self.keyboardView.frame;

    BOOL userIsDraggingNearThresholdForDismissing = (touch.y > dragThresholdY);

    self.keyboardView.userInteractionEnabled = !userIsDraggingNearThresholdForDismissing;

    switch (pan.state) {
        case UIGestureRecognizerStateChanged:
        {
            newKeyboardViewFrame.origin.y = touch.y + self.keyboardTriggerPoint.y;

            //  bound frame between bottom of view and height of keyboard
            newKeyboardViewFrame.origin.y = MIN(newKeyboardViewFrame.origin.y, contextViewWindowHeight);
            newKeyboardViewFrame.origin.y = MAX(newKeyboardViewFrame.origin.y, contextViewWindowHeight - keyboardViewHeight);

            if (CGRectGetMinY(newKeyboardViewFrame) == CGRectGetMinY(self.keyboardView.frame)) {
                return;
            }

            [UIView animateWithDuration:0.0
                                  delay:0.0
                                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone
                             animations:^{
                                 self.keyboardView.frame = newKeyboardViewFrame;
                             }
                             completion:nil];
        }
            break;

        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            BOOL keyboardViewIsHidden = (CGRectGetMinY(self.keyboardView.frame) >= contextViewWindowHeight);
            if (keyboardViewIsHidden) {
                [self zng_resetKeyboardAndTextView];
                return;
            }

            CGPoint velocity = [pan velocityInView:self.contextView];
            BOOL userIsScrollingDown = (velocity.y > 0.0f);
            BOOL shouldHide = (userIsScrollingDown && userIsDraggingNearThresholdForDismissing);

            newKeyboardViewFrame.origin.y = shouldHide ? contextViewWindowHeight : (contextViewWindowHeight - keyboardViewHeight);

            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseOut
                             animations:^{
                                 self.keyboardView.frame = newKeyboardViewFrame;
                             }
                             completion:^(BOOL finished) {
                                 self.keyboardView.userInteractionEnabled = !shouldHide;

                                 if (shouldHide) {
                                     [self zng_resetKeyboardAndTextView];
                                 }
                             }];
        }
            break;

        default:
            break;
    }
}

@end
