//
//  ZNGConversationTypingIndicatorCell.m
//  Pods
//
//  Created by Jason Neel on 8/31/17.
//
//

#import "ZNGConversationTypingIndicatorCell.h"

@implementation ZNGConversationTypingIndicatorCell
{
    
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    CAShapeLayer * tempCircle = [[CAShapeLayer alloc] init];
    UIBezierPath * path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.0, 0.0, 10.0, 10.0)];
    tempCircle.path = path.CGPath;
    tempCircle.frame = CGRectMake(self.layer.bounds.size.width - 10.0, self.layer.bounds.size.height - 10.0, 10.0, 10.0);
    
    [self.layer addSublayer:tempCircle];
}

@end
