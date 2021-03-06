//
//  ZNGTableViewCell.m
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import "ZNGTableViewCell.h"

@interface ZNGTableViewCell ()

@end

@implementation ZNGTableViewCell

+ (NSString *)cellReuseIdentifier
{
    return NSStringFromClass([self class]);
}

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer isKindOfClass:[UIScreenEdgePanGestureRecognizer class]]) {
        return YES;
    }
    
    return NO;
}

@end
