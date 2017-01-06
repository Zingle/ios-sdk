//
//  ZNGImageAttachment.m
//  Pods
//
//  Created by Jason Neel on 10/3/16.
//
//

#import "ZNGImageAttachment.h"

@implementation ZNGImageAttachment
{
    CGFloat imageScale;
    UIImage * scaledImage;
}

- (id) initWithData:(NSData *)contentData ofType:(NSString *)uti
{
    self = [super initWithData:contentData ofType:uti];
    
    if (self != nil) {
        _maxDisplayHeight = 120.0;
    }
    
    return self;
}

- (UIImage *) imageForBounds:(CGRect)imageBounds textContainer:(NSTextContainer *)textContainer characterIndex:(NSUInteger)charIndex
{
    return scaledImage ?: [super imageForBounds:imageBounds textContainer:textContainer characterIndex:charIndex];
}

- (void) setImageScale:(CGFloat)newImageScale
{
    if (imageScale == newImageScale) {
        return;
    }
    
    imageScale = newImageScale;
    scaledImage = nil;
    
    if ((newImageScale == 0.0) || (newImageScale == 1.0)) {
        // We can use default scale.
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        CGFloat width = self.image.size.width * newImageScale;
        CGFloat height = self.image.size.height * newImageScale;
        CGSize newSize = CGSizeMake(width, height);
        
        UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
        [self.image drawInRect:CGRectMake(0.0, 0.0, width, height)];
        UIImage * newScaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            scaledImage = newScaledImage;
        });
    });
}

- (CGRect) attachmentBoundsForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex
{
    if ((self.image.size.height == 0) || (self.image.size.width == 0)) {
        return [super attachmentBoundsForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];
    }
    
    CGFloat downscaleHeight = self.maxDisplayHeight / self.image.size.height;
    CGFloat downscaleWidth = lineFrag.size.width / self.image.size.width;
    
    if ((downscaleHeight >= 1.0) && (downscaleWidth >= 1.0)) {
        // Our image will fit as is
        [self setImageScale:1.0];
        return [super attachmentBoundsForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];
    }
    
    CGFloat downscale = MIN(downscaleWidth, downscaleHeight);
    
    [self setImageScale:downscale];
    
    return CGRectIntegral(CGRectMake(0.0, 0.0, self.image.size.width * downscale, self.image.size.height * downscale));
}

@end
