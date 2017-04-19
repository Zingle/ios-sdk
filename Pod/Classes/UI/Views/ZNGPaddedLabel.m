//
//  ZNGPaddedLabel.m
//  Pods
//
//  Created by Jason Neel on 4/19/17.
//
//

#import "ZNGPaddedLabel.h"

@implementation ZNGPaddedLabel

- (void) setTextInsets:(UIEdgeInsets)textInsets
{
    if (!UIEdgeInsetsEqualToEdgeInsets(textInsets, self.textInsets)) {
        _textInsets = textInsets;
        [self invalidateIntrinsicContentSize];
    }
}

- (CGRect) textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    if ([self.text length] == 0) {
        return [super textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
    }
    
    CGRect insetRect = UIEdgeInsetsInsetRect(bounds, self.textInsets);
    CGRect textRect = [super textRectForBounds:insetRect limitedToNumberOfLines:numberOfLines];
    UIEdgeInsets invertedInsets = UIEdgeInsetsMake(-self.textInsets.top, -self.textInsets.left, -self.textInsets.bottom, -self.textInsets.right);
    return UIEdgeInsetsInsetRect(textRect, invertedInsets);
}

- (void) drawTextInRect:(CGRect)rect
{
    if ([self.text length] == 0) {
        return [super drawTextInRect:rect];
    }
    
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.textInsets)];
}

@end
