//
//  ZNGPulsatingBarButtonImage.h
//  Pods
//
//  Created by Jason Neel on 7/20/16.
//
//

#import <UIKit/UIKit.h>

@interface ZNGPulsatingBarButtonImage : UIBarButtonItem

- (id) initWithImage:(UIImage *)image selectedBackgroundImage:(UIImage * _Nullable)highlightImage tintColor:(UIColor *)tintColor selectedColor:(UIColor * _Nullable)selectedColor target:(id)target action:(SEL)action;

- (void) emphasize;

@property (nonatomic, assign) BOOL selected;

@property (nonatomic, assign) NSTimeInterval pulsateDuration;
@property (nonatomic, readonly) BOOL isPulsating;

@property (nonatomic, strong) UIImage * emphasisImage;

@end
