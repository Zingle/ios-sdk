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
    UIImageView * highlightView;
}

- (id) initWithImage:(UIImage *)image selectedBackgroundImage:(UIImage * _Nullable)highlightImage tintColor:(UIColor *)tintColor pulsateColor:(UIColor * _Nullable)pulsateColor selectedColor:(UIColor * _Nullable)selectedColor target:(id)target action:(SEL)action
{
    if (image == nil) {
        return nil;
    }
    
    CGRect frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
    UIView * view = [[UIView alloc] initWithFrame:frame];
    
    self = [super initWithCustomView:view];
    
    if (self != nil) {
        _pulsateDuration = 2.0;
        
        if ((highlightImage != nil) && (selectedColor != nil)) {
            UIImage * highlightTemplateImage = [highlightImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            highlightView = [[UIImageView alloc] initWithFrame:frame];
            highlightView.image = highlightTemplateImage;
            highlightView.tintColor = selectedColor;
            highlightView.alpha = 0.0;
            [view addSubview:highlightView];
        }
        
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

- (void) setSelected:(BOOL)selected
{
    _selected = selected;
    highlightView.alpha = selected ? 1.0 : 0.0;
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
