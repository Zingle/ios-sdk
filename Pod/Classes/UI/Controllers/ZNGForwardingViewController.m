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
}

- (void) dealloc
{
    [self removeObserver:self forKeyPath:kToolbarHeightKVOPath];
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
