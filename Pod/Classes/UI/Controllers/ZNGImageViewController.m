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
}

- (void) setImage:(UIImage *)image
{
    _image = image;
    self.imageView.image = image;
}

@end
