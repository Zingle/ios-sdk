//
//  ZNGImageViewController.m
//  Pods
//
//  Created by Jason Neel on 6/28/16.
//
//

#import "ZNGImageViewController.h"

@interface ZNGImageViewController ()

@end

@implementation ZNGImageViewController

- (id) init
{
    return [super initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView.image = self.image;
    
    UIBarButtonItem * shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(pressedShare:)];
    self.navigationItem.rightBarButtonItem = shareButton;
}

- (void) setImage:(UIImage *)image
{
    _image = image;
    self.imageView.image = image;
}
                                     
- (void) pressedShare:(id)sender
{
    UIActivityViewController * shareView = [[UIActivityViewController alloc] initWithActivityItems:@[self.image] applicationActivities:nil];
    shareView.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:shareView animated:YES completion:nil];
}

@end
