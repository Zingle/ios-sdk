//
//  ZNGImageViewerController.h
//  Pods
//
//  Created by Ryan Farley on 3/8/16.
//
//

#import <UIKit/UIKit.h>

@interface ZNGImageViewerController : UIViewController<UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

+ (instancetype)imageViewerController;

@end
