//
//  ZNGImageAvatar.m
//  Pods
//
//  Created by Jason Neel on 1/11/17.
//
//

#import "ZNGImageAvatar.h"

@implementation ZNGImageAvatar

- (id) initWithImage:(UIImage *)theImage backgroundColor:(nullable UIColor *)backgroundColor size:(CGSize)theSize
{
    NSParameterAssert(!CGSizeEqualToSize(theSize, CGSizeZero));
    self = [super init];
    
    if (self != nil) {
        _size = theSize;
        _backgroundColor = backgroundColor;
        [self drawImageWithBackground:theImage];
    }
    
    return self;
}

- (void) drawImageWithBackground:(UIImage *)image
{
    if (image == nil) {
        _image = nil;
        return;
    }
    
    if (self.backgroundColor == nil) {
        // This is easy.  Just return the same image.
        _image = image;
    } else {
        // Draw an image with the supplied image centered over the supplied background.
        CGRect rect = CGRectMake(0.0, 0.0, self.size.width, self.size.height);
        CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
        
        // Setup context
        UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // Background circle
        CGContextSetFillColorWithColor(context, [self.backgroundColor CGColor]);
        CGContextFillEllipseInRect(context, rect);
        
        // Image
        CGPoint imageTopLeft = CGPointMake(center.x - (image.size.width * 0.5), center.y - (image.size.height * 0.5));
        [image drawAtPoint:imageTopLeft];
        
        // Save
        _image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
}

- (void) setSize:(CGSize)size
{
    _size = size;
    [self drawImageWithBackground:self.image];
}

- (void) setImage:(UIImage *)image
{
    [self drawImageWithBackground:image];
}

- (void) setBackgroundColor:(UIColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    [self drawImageWithBackground:self.image];
}

- (UIImage *)avatarImage
{
    return self.image;
}

- (UIImage *) avatarHighlightedImage
{
    return nil;
}

- (UIImage *) avatarPlaceholderImage
{
    return nil;
}

@end
