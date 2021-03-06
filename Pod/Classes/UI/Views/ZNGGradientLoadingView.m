//
//  ZNGGradientLoadingView.m
//  Pods
//
//  Created by Jason Neel on 9/28/16.
//
//

#import "ZNGGradientLoadingView.h"

static NSString * const AnimationKey = @"movingGradientAnimation";

@implementation ZNGGradientLoadingView
{
    BOOL animating;
    
    NSArray<NSNumber *> * colorLocations;
    
    CAGradientLayer * gradient;
    
    UIColor * _centerColor;
    UIColor * _edgeColor;
}

- (void) setHidesWhenStopped:(BOOL)hidesWhenStopped
{
    _hidesWhenStopped = hidesWhenStopped;
    
    if ((hidesWhenStopped) && (!animating)) {
        self.hidden = YES;
    }
}

- (void) setCenterColor:(UIColor *)centerColor
{
    _centerColor = centerColor;
    [self setupGradientLayer];
}

- (UIColor *) centerColor
{
    if (_centerColor == nil) {
        return [UIColor clearColor];
    }
    
    return _centerColor;
}

- (void) setEdgeColor:(UIColor *)edgeColor
{
    _edgeColor = edgeColor;
    [self setupGradientLayer];
}

- (UIColor *) edgeColor
{
    if (_edgeColor == nil) {
        return [UIColor clearColor];
    }
    
    return _edgeColor;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self setupGradientLayer];
}

- (void) prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    [self setupGradientLayer];
}

- (void) layoutSubviews
{
    gradient.frame = self.layer.bounds;
}

- (void) setupGradientLayer
{
    if (gradient == nil) {
        gradient = [[CAGradientLayer alloc] init];
        gradient.frame = self.layer.bounds;
        [self.layer addSublayer:gradient];
        
        colorLocations = @[ @(-1.0), @(-0.6), @(-0.4), @(0.0), @(0.4), @(0.6), @(1.0) ];
    }
    
    gradient.startPoint = CGPointMake(0.0, 0.5);
    gradient.endPoint = CGPointMake(1.0, 0.5);
    id edgeColor = (id)[self.edgeColor CGColor];
    id centerColor = (id)[self.centerColor CGColor];
    gradient.colors = @[centerColor, edgeColor, edgeColor, centerColor, edgeColor, edgeColor, centerColor];
    gradient.locations = colorLocations;
}

- (void) startAnimating
{
    if (animating) {
        return;
    }
    
    animating = YES;
    
    [gradient removeAnimationForKey:AnimationKey];
    
    NSMutableArray<NSNumber *> * toValue = [[NSMutableArray alloc] initWithCapacity:[colorLocations count]];
    
    for (NSNumber * number in colorLocations) {
        [toValue addObject:@(number.floatValue + 1.0)];
    }
    
    CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"locations"];
    animation.fromValue = colorLocations;
    animation.toValue = toValue;
    animation.repeatCount = FLT_MAX;
    animation.duration = 1.0;
    
    [gradient addAnimation:animation forKey:AnimationKey];
    
    self.hidden = NO;
}

- (void) stopAnimating
{
    if (!animating) {
        return;
    }
    
    animating = NO;
    [gradient removeAnimationForKey:AnimationKey];
    
    if (self.hidesWhenStopped) {
        self.hidden = true;
    }
}

@end
