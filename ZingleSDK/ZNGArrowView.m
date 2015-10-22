//
//  ZNGArrowView.m
//  ZingleSDK
//
//  Copyright © 2015 Zingle.me. All rights reserved.
//

#import "ZNGArrowView.h"

@implementation ZNGArrowView

- (id)initWithFrame:(CGRect)frame
{
    if( self = [super initWithFrame:frame] ) {
        self.backgroundColor = [UIColor clearColor];
        self.color = [UIColor grayColor];
        self.direction = @"down";
    }
    return self;
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    [self setNeedsDisplay];
}

- (void)setDirection:(NSString *)direction
{
    _direction = direction;
    [self setNeedsDisplay];
}

- (void)setBias:(int)bias
{
    _bias = bias;
    [self setNeedsDisplay];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, self.color.CGColor);
    
    if( [self.direction isEqualToString:@"left"] ) {
        CGContextMoveToPoint(context, 0, [self verticalMiddleApex]);
        CGContextAddLineToPoint(context, self.frame.size.width, 0);
        CGContextAddLineToPoint(context, self.frame.size.width, self.frame.size.height);
    } else if( [self.direction isEqualToString:@"right"] ) {
        CGContextMoveToPoint(context, 0, 0);
        CGContextAddLineToPoint(context, self.frame.size.width, [self verticalMiddleApex]);
        CGContextAddLineToPoint(context, 0, self.frame.size.height);
    } else if( [self.direction isEqualToString:@"down"] ) {
        CGContextMoveToPoint(context, 0, 0);
        CGContextAddLineToPoint(context, self.frame.size.width, 0);
        CGContextAddLineToPoint(context, [self horizontalCenterApex], self.frame.size.height);
    } else if( [self.direction isEqualToString:@"up"] ) {
        CGContextMoveToPoint(context, 0, self.frame.size.height);
        CGContextAddLineToPoint(context, [self horizontalCenterApex], 0);
        CGContextAddLineToPoint(context, self.frame.size.width, self.frame.size.height);
    }
    
    CGContextFillPath(context);
}

- (int)horizontalCenterApex
{
    int bias = ( [self.direction isEqualToString:@"right"] || [self.direction isEqualToString:@"up"] ) ? -self.bias : self.bias;
    
    int baseApex = (self.frame.size.width / 2);
    int biasAmount = baseApex * (bias * .01);
    return baseApex + biasAmount;
}

- (int)verticalMiddleApex
{
    int bias = ( [self.direction isEqualToString:@"right"] || [self.direction isEqualToString:@"up"] ) ? -self.bias : self.bias;
    
    int baseApex = (self.frame.size.height / 2);
    int biasAmount = baseApex * (bias * .01);
    return baseApex + biasAmount;
}

@end
