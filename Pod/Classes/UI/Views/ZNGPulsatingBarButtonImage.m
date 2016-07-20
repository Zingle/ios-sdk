//
//  ZNGPulsatingBarButtonImage.m
//  Pods
//
//  Created by Jason Neel on 7/20/16.
//
//

#import "ZNGPulsatingBarButtonImage.h"

@implementation ZNGPulsatingBarButtonImage
{
    UIImageView * pulsateView;
}

- (id) initWithImage:(UIImage *)image tintColor:(UIColor *)tintColor pulsateColor:(UIColor *)pulsateColor target:(id)target action:(SEL)action
{
    if (image == nil) {
        return nil;
    }
    
    CGRect frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
    UIView * view = [[UIView alloc] initWithFrame:frame];
    
    self = [super initWithCustomView:view];
    
    if (self != nil) {
        _pulsateDuration = 2.0;
        
        UIImage * templateImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIButton * button = [[UIButton alloc] initWithFrame:frame];
        [button setImage:templateImage forState:UIControlStateNormal];
        button.tintColor = tintColor;
        [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:button];
        
        if (pulsateColor != nil) {
            pulsateView = [[UIImageView alloc] initWithFrame:frame];
            pulsateView.image = templateImage;
            pulsateView.tintColor = pulsateColor;
            pulsateView.userInteractionEnabled = NO;
            pulsateView.alpha = 0.0;
            [view addSubview:pulsateView];
        }
        
    }
    
    return self;
}

- (void) startPulsating
{
    // Do nothing if we are already pulsating
    if (self.isPulsating) {
        return;
    }
    
    _isPulsating = YES;
    [UIView animateKeyframesWithDuration:self.pulsateDuration delay:0.0 options:UIViewKeyframeAnimationOptionRepeat|UIViewKeyframeAnimationOptionAutoreverse animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
            pulsateView.alpha = 1.0;
        }];
    } completion:nil];
}

- (void) stopPulsating
{
    _isPulsating = NO;
    [pulsateView.layer removeAllAnimations];
    pulsateView.alpha = 0.0;
}

@end
