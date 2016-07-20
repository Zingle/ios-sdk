//
//  ZNGPulsatingBarButtonImage.h
//  Pods
//
//  Created by Jason Neel on 7/20/16.
//
//

#import <UIKit/UIKit.h>

@interface ZNGPulsatingBarButtonImage : UIBarButtonItem

- (id) initWithImage:(UIImage *)image tintColor:(UIColor *)tintColor pulsateColor:(UIColor *)pulsateColor target:(id)target action:(SEL)action;

- (void) startPulsating;
- (void) stopPulsating;

@property (nonatomic, assign) NSTimeInterval pulsateDuration;
@property (nonatomic, readonly) BOOL isPulsating;

@end
