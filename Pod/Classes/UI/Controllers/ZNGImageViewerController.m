//
//  ZNGImageViewerController.m
//  Pods
//
//  Created by Ryan Farley on 3/8/16.
//
//

#import "ZNGImageViewerController.h"

@interface ZNGImageViewerController ()

@end

@implementation ZNGImageViewerController

+ (instancetype)imageViewerController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([ZNGImageViewerController class])
                                          bundle:[NSBundle bundleForClass:[ZNGImageViewerController class]]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 6.0;
    self.scrollView.contentSize = self.imageView.frame.size;
    self.scrollView.delegate = self;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.scrollView.zoomScale == self.scrollView.minimumZoomScale) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)handleSingleTap:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
