//
//  ZNGConversationTypingIndicatorCell.m
//  Pods
//
//  Created by Jason Neel on 8/31/17.
//
//

#import "ZNGConversationTypingIndicatorCell.h"

static const CGFloat bubbleDiameter = 7.0;

@implementation ZNGConversationTypingIndicatorCell

+ (CGSize) size
{
    return CGSizeMake(60.0, 38.0);
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    // Draw the three bouncing circles for typing indicator magic.
    CAShapeLayer * circle1 = [[CAShapeLayer alloc] init];
    UIBezierPath * path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.0, 0.0, bubbleDiameter, bubbleDiameter)];
    circle1.path = path.CGPath;
    circle1.fillColor = [[UIColor whiteColor] CGColor];
    circle1.frame = CGRectMake(self.bouncingCircleContainerView.layer.bounds.size.width - (bubbleDiameter  * 5.0), self.bouncingCircleContainerView.layer.bounds.size.height - bubbleDiameter, bubbleDiameter, bubbleDiameter);
    
    CAShapeLayer * circle2 = [[CAShapeLayer alloc] init];
    path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.0, 0.0, bubbleDiameter, bubbleDiameter)];
    circle2.path = path.CGPath;
    circle2.fillColor = circle1.fillColor;
    circle2.frame = CGRectMake(self.bouncingCircleContainerView.layer.bounds.size.width - (bubbleDiameter  * 3.0), self.bouncingCircleContainerView.layer.bounds.size.height - bubbleDiameter, bubbleDiameter, bubbleDiameter);
    
    CAShapeLayer * circle3 = [[CAShapeLayer alloc] init];
    path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.0, 0.0, bubbleDiameter, bubbleDiameter)];
    circle3.path = path.CGPath;
    circle3.fillColor = circle1.fillColor;
    circle3.frame = CGRectMake(self.bouncingCircleContainerView.layer.bounds.size.width - bubbleDiameter, self.bouncingCircleContainerView.layer.bounds.size.height - bubbleDiameter, bubbleDiameter, bubbleDiameter);
    
    [self.bouncingCircleContainerView.layer addSublayer:circle1];
    [self.bouncingCircleContainerView.layer addSublayer:circle2];
    [self.bouncingCircleContainerView.layer addSublayer:circle3];
    
    CAKeyframeAnimation * bounce = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
    bounce.repeatCount = FLT_MAX;
    bounce.duration = 1.6;
    bounce.values = @[@(0.0), @(-12.0), @(0.0), @(0.0)];
    bounce.keyTimes = @[@(0.0), @(0.1), @(0.2), @(1.0)];
    bounce.timingFunctions = @[
                               [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                               [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
                               [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear],
                               ];
    
    [circle1 addAnimation:bounce forKey:@"bounce"];
    
    bounce.timeOffset = -0.1;
    [circle2 addAnimation:bounce forKey:@"bounce"];
    
    bounce.timeOffset = -0.2;
    [circle3 addAnimation:bounce forKey:@"bounce"];
}

@end
