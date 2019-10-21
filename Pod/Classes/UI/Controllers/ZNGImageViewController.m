//
//  ZNGImageViewController.m
//  Pods
//
//  Created by Jason Neel on 6/28/16.
//
//

#import "ZNGImageViewController.h"

@import SDWebImage;

@interface ZNGImageViewController ()

@end

@implementation ZNGImageViewController

- (id) init
{
    return [super initWithNibName:NSStringFromClass([ZNGImageViewController class]) bundle:[NSBundle bundleForClass:[ZNGImageViewController class]]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.imageView sd_setImageWithURL:self.imageURL placeholderImage:nil];
    
    UIBarButtonItem * shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(pressedShare:)];
    self.navigationItem.rightBarButtonItem = shareButton;
}

- (void) setImageURL:(NSURL *)imageURL
{
    _imageURL = [imageURL copy];
    [self.imageView sd_setImageWithURL:_imageURL placeholderImage:nil];
}
                                     
- (void) pressedShare:(id)sender
{
    UIImage * image = self.imageView.image;
    
    if (image == nil)
    {
        return;
    }
    
    UIActivityViewController * shareView = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
    shareView.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:shareView animated:YES completion:nil];
}

@end
