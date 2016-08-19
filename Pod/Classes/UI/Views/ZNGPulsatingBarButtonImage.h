//
//  ZNGPulsatingBarButtonImage.h
//  Pods
//
//  Created by Jason Neel on 7/20/16.
//
//

#import <UIKit/UIKit.h>

@interface ZNGPulsatingBarButtonImage : UIBarButtonItem

NS_ASSUME_NONNULL_BEGIN

- (id) initWithImage:(UIImage *)image selectedImage:(UIImage * _Nullable)highlightImage target:(id)target action:(SEL)action;

- (void) emphasize;

@property (nonatomic, assign) BOOL selected;

@property (nonatomic, assign) NSTimeInterval pulsateDuration;
@property (nonatomic, readonly) BOOL isPulsating;

@property (nonatomic, strong, nullable) UIImage * emphasisImage;
@property (nonatomic, strong, nullable) UIColor * emphasisColor;

NS_ASSUME_NONNULL_END

@end
