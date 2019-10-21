//
//  ZNGImageViewController.h
//  Pods
//
//  Created by Jason Neel on 6/28/16.
//
//

#import <UIKit/UIKit.h>

@class SDAnimatedImageView;

@interface ZNGImageViewController : UIViewController

@property (nonatomic, strong) IBOutlet SDAnimatedImageView * imageView;
@property (nonatomic, copy) NSURL * imageURL;

@end
