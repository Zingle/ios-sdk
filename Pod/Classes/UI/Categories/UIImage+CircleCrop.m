//
//  UIImage+CircleCrop.m
//  ZingleSDK
//
//  Created by Jason Neel on 1/22/18.
//

#import "UIImage+CircleCrop.h"

@implementation UIImage (CircleCrop)

- (UIImage *) imageCroppedToCircleOfDiameter:(CGFloat)diameter withScale:(CGFloat)screenScale
{
    CGFloat smallestDimension = MIN(self.size.width, self.size.height);
    CGFloat downscale = diameter / smallestDimension;
    CGSize downscaledSize = CGSizeMake(self.size.width * downscale, self.size.height * downscale);
    
    CGRect rect = CGRectMake(0.0, 0.0, diameter, diameter);
    UIGraphicsBeginImageContextWithOptions(rect.size, false, screenScale);
    [[UIBezierPath bezierPathWithOvalInRect:rect] addClip];
    CGFloat radius = diameter / 2.0;
    CGFloat halfWidth = downscaledSize.width / 2.0;
    CGFloat halfHeight = downscaledSize.height / 2.0;
    CGPoint imageOrigin = CGPointMake(radius - halfWidth, radius - halfHeight);
    
    [self drawInRect:CGRectMake(imageOrigin.x, imageOrigin.y, downscaledSize.width, downscaledSize.height)];
    
    UIImage * result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

@end
