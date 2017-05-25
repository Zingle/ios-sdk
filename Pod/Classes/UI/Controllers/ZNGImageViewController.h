//
//  ZNGImageViewController.h
//  Pods
//
//  Created by Jason Neel on 6/28/16.
//
//

#import <UIKit/UIKit.h>

@class FLAnimatedImageView;

@interface ZNGImageViewController : UIViewController

@property (nonatomic, strong) IBOutlet FLAnimatedImageView * imageView;
@property (nonatomic, copy) NSURL * imageURL;

@end
