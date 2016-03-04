//
//  ZNGArrowView.m
//  ZingleSDK
//
//  Copyright © 2015 Zingle.me. All rights reserved.
//

#import "ZNGArrowView.h"

@implementation ZNGArrowView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if( self = [super initWithCoder:aDecoder] ) {
        self.backgroundColor = [UIColor clearColor];
        self.color = [UIColor grayColor];
        self.direction = ZNGArrowDirectionDown;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if( self = [super initWithFrame:frame] ) {
        self.backgroundColor = [UIColor clearColor];
        self.color = [UIColor grayColor];
        self.direction = ZNGArrowDirectionDown;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGFloat layerHeight = self.layer.frame.size.height;
    CGFloat layerWidth = self.layer.frame.size.width;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    
    switch (self.direction) {
        case ZNGArrowDirectionLeft:
            [bezierPath moveToPoint:CGPointMake(layerWidth, 0)];
            [bezierPath addLineToPoint:CGPointMake(layerWidth, layerHeight)];
            [bezierPath addLineToPoint:CGPointMake(0, [self verticalMiddleApex])];
            [bezierPath addLineToPoint:CGPointMake(layerWidth, 0)];
            break;
            
        case ZNGArrowDirectionRight:
            [bezierPath moveToPoint:CGPointMake(0, 0)];
            [bezierPath addLineToPoint:CGPointMake(0, layerHeight)];
            [bezierPath addLineToPoint:CGPointMake(layerWidth, [self verticalMiddleApex])];
            [bezierPath addLineToPoint:CGPointMake(0, 0)];
            break;
            
        case ZNGArrowDirectionDown:
            [bezierPath moveToPoint:CGPointMake(0, 0)];
            [bezierPath addLineToPoint:CGPointMake(layerWidth, 0)];
            [bezierPath addLineToPoint:CGPointMake([self horizontalCenterApex], layerHeight)];
            [bezierPath addLineToPoint:CGPointMake(0, 0)];
            break;
            
        case ZNGArrowDirectionUp:
            [bezierPath moveToPoint:CGPointMake(0, layerHeight)];
            [bezierPath addLineToPoint:CGPointMake(layerWidth, layerHeight)];
            [bezierPath addLineToPoint:CGPointMake([self horizontalCenterApex], 0)];
            [bezierPath addLineToPoint:CGPointMake(0, layerHeight)];
            break;
            
        default:
            break;
    }

    [bezierPath closePath];
    
    [self.color setFill];
    [bezierPath fill];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    [shapeLayer setPath:[bezierPath CGPath]];
    self.layer.mask = shapeLayer;
}

- (int)horizontalCenterApex
{
    int bias = ( self.direction == ZNGArrowDirectionRight || self.direction == ZNGArrowDirectionUp ) ? -self.bias : self.bias;
    
    int baseApex = (self.frame.size.width / 2);
    int biasAmount = baseApex * (bias * .01);
    return baseApex + biasAmount;
}

- (int)verticalMiddleApex
{
    int bias = ( self.direction == ZNGArrowDirectionRight || self.direction == ZNGArrowDirectionUp ) ? -self.bias : self.bias;
    
    int baseApex = (self.frame.size.height / 2);
    int biasAmount = baseApex * (bias * .01);
    return baseApex + biasAmount;
}

@end
