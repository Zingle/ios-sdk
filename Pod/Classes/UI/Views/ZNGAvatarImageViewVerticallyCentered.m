//
//  ZNGAvatarImageViewVerticallyCentered.m
//  Pods
//
//  Created by Jason Neel on 4/12/17.
//
//

#import "ZNGAvatarImageViewVerticallyCentered.h"

@implementation ZNGAvatarImageViewVerticallyCentered

- (CGPoint) editImageLocation
{
    CGSize size = [self intrinsicContentSize];
    CGFloat x = size.width - self.editIconImage.size.width;
    CGFloat y = (size.height / 2.0) - (self.editIconImage.size.height / 2.0);
    return CGPointMake(x, y);
}

@end
