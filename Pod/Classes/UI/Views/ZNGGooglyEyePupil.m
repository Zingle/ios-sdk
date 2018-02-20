//
//  ZNGGooglyEyePupil.m
//  ZingleSDK
//
//  Created by Jason Neel on 2/19/18.
//

#import "ZNGGooglyEyePupil.h"

@implementation ZNGGooglyEyePupil

- (void) layoutSubviews
{
    [super layoutSubviews];
    [self setupMask];
}

- (void) setupMask
{
    CAShapeLayer * mask = [[CAShapeLayer alloc] init];
    UIBezierPath * maskPath = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    mask.path = [maskPath CGPath];
    self.layer.mask = mask;
}

- (UIDynamicItemCollisionBoundsType) collisionBoundsType
{
    return UIDynamicItemCollisionBoundsTypeEllipse;
}

@end
