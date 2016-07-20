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
    UIImage * templateImage;
    UIView * containerView;
    UIImageView * highlightView;
    CGRect frame;
}

- (id) initWithImage:(UIImage *)image selectedBackgroundImage:(UIImage * _Nullable)highlightImage tintColor:(UIColor *)tintColor selectedColor:(UIColor * _Nullable)selectedColor target:(id)target action:(SEL)action
{
    if (image == nil) {
        return nil;
    }
    
    frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
    containerView = [[UIView alloc] initWithFrame:frame];
    
    self = [super initWithCustomView:containerView];
    
    if (self != nil) {
        _pulsateDuration = 2.0;
        
        if ((highlightImage != nil) && (selectedColor != nil)) {
            UIImage * highlightTemplateImage = [highlightImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            highlightView = [[UIImageView alloc] initWithFrame:frame];
            highlightView.image = highlightTemplateImage;
            highlightView.tintColor = selectedColor;
            highlightView.alpha = 0.0;
            [containerView addSubview:highlightView];
        }
        
        templateImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIButton * button = [[UIButton alloc] initWithFrame:frame];
        [button setImage:templateImage forState:UIControlStateNormal];
        button.tintColor = tintColor;
        [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        [containerView addSubview:button];
    }
    
    return self;
}

- (void) setSelected:(BOOL)selected
{
    _selected = selected;
    highlightView.alpha = selected ? 1.0 : 0.0;
}

- (void) setEmphasisImage:(UIImage *)emphasisImage
{
    _emphasisImage = [emphasisImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void) emphasize
{
    UIImage * emphasisImage = (self.emphasisImage == nil) ? templateImage : self.emphasisImage;
    emphasisImage = [emphasisImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    UIImageView * emphasisView = [[UIImageView alloc] initWithImage:emphasisImage];
    emphasisView.frame = frame;
    emphasisView.tintColor = [UIColor whiteColor];
    
    [containerView addSubview:emphasisView];
    [UIView animateWithDuration:1.0 animations:^{
        emphasisView.transform = CGAffineTransformMakeScale(2.5, 2.5);
        emphasisView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [emphasisView removeFromSuperview];
    }];
}

@end
