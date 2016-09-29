//
//  ZNGDashedBorderLabel.m
//  Pods
//
//  Created by Jason Neel on 9/28/16.
//
//

#import "ZNGDashedBorderLabel.h"

@implementation ZNGDashedBorderLabel
{
    CAShapeLayer * borderLine;
}

#pragma mark - IBInspectable properties
- (void) setBorderColor:(UIColor *)borderColor
{
    _borderColor = [borderColor copy];
    [self drawBorder];
}

- (void) setBorderWidth:(CGFloat)borderWidth
{
    _borderWidth = borderWidth;
    [self drawBorder];
}

- (void) setTextInset:(CGFloat)textInset
{
    _textInset = textInset;
    [self invalidateIntrinsicContentSize];
}

- (void) setDashed:(BOOL)dashed
{
    _dashed = dashed;
    [self drawBorder];
}

- (void) setCornerRadius:(CGFloat)cornerRadius
{
    self.layer.cornerRadius = cornerRadius;
    [self drawBorder];
}

- (CGFloat) cornerRadius
{
    return self.layer.cornerRadius;
}

#pragma mark - Drawing
- (void) drawBorder
{
    [borderLine removeFromSuperlayer];
    self.layer.masksToBounds = (self.borderWidth > 0.0);
    
    CAShapeLayer * border = [[CAShapeLayer alloc] init];
    border.strokeColor = [self.borderColor CGColor];
    border.fillColor = nil;
    border.lineWidth = self.borderWidth;
    int dashSpacing = (self.dashed) ? 4 : 0;
    border.lineDashPattern = @[@(4), @(dashSpacing)];
    
    borderLine = border;
    
    [self.layer addSublayer:border];
}

- (void) layoutSubviews
{
    borderLine.path = [[UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.cornerRadius] CGPath];
    borderLine.frame = self.bounds;
}

- (CGRect) textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    CGFloat inset = self.textInset;
    UIEdgeInsets insets = UIEdgeInsetsMake(inset, inset, inset, inset);
    CGRect insetRect = UIEdgeInsetsInsetRect(bounds, insets);
    CGRect textRect = [super textRectForBounds:insetRect limitedToNumberOfLines:numberOfLines];
    UIEdgeInsets invertedInsets = UIEdgeInsetsMake(-insets.top, -insets.left, -insets.bottom, -insets.right);
    return UIEdgeInsetsInsetRect(textRect, invertedInsets);
}

- (void) drawTextInRect:(CGRect)rect
{
    CGFloat inset = self.textInset;
    UIEdgeInsets insets = UIEdgeInsetsMake(inset, inset, inset, inset);
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}


@end
