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
    UIView * containerView;
    UIButton * button;
    CGRect frame;
}

- (id) initWithImage:(UIImage *)image selectedImage:(UIImage * _Nullable)highlightImage target:(id)target action:(SEL)action
{
    NSParameterAssert(image);
    
    frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
    containerView = [[UIView alloc] initWithFrame:frame];
    
    self = [super initWithCustomView:containerView];
    
    if (self != nil) {
        _pulsateDuration = 2.0;
        
        button = [[UIButton alloc] initWithFrame:frame];
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        
        if (highlightImage != nil)  {
            [button setImage:highlightImage forState:UIControlStateSelected];
        }
        
        [containerView addSubview:button];
    }
    
    return self;
}

- (void) setSelected:(BOOL)selected
{
    _selected = selected;
    button.selected = selected;
}

- (void) setEmphasisImage:(UIImage *)emphasisImage
{
    _emphasisImage = [emphasisImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void) emphasize
{
    UIImage * emphasisImage = (self.emphasisImage == nil) ? button.currentImage : self.emphasisImage;
    emphasisImage = [emphasisImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    UIImageView * emphasisView = [[UIImageView alloc] initWithImage:emphasisImage];
    emphasisView.frame = frame;
    emphasisView.tintColor = self.emphasisColor ?: [UIColor whiteColor];
    
    [containerView addSubview:emphasisView];
    [UIView animateWithDuration:1.0 animations:^{
        emphasisView.transform = CGAffineTransformMakeScale(2.5, 2.5);
        emphasisView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [emphasisView removeFromSuperview];
    }];
}

@end
