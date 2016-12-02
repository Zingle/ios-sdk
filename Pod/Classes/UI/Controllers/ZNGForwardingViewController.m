//
//  ZNGForwardingViewController.m
//  Pods
//
//  Created by Jason Neel on 12/1/16.
//
//

#import "ZNGForwardingViewController.h"

@interface ZNGForwardingViewController ()

@end

@implementation ZNGForwardingViewController
{
    BOOL userHasInteracted; // Flag used to determine if we should confirm before dismissing
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Our message is %@", self.message);
}

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
