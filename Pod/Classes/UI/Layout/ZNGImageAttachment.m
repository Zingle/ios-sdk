//
//  ZNGImageAttachment.m
//  Pods
//
//  Created by Jason Neel on 10/3/16.
//
//

#import "ZNGImageAttachment.h"
#import "ZNGLogging.h"

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGImageAttachment
{
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
    if (_imageScale == newImageScale) {
        return;
    }
    
    _imageScale = newImageScale;
    scaledImage = nil;
    
    if ((newImageScale <= 0.0) || (newImageScale >= 1.0)) {
        // We can use default scale.
        _imageScale = 0.0;
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
        CGRect bounds = [super attachmentBoundsForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];
        ZNGLogDebug(@"Returning %@ as bounds for a %@", NSStringFromCGRect(bounds), [self class]);
        return bounds;
    }
    
    CGFloat downscaleHeight = self.maxDisplayHeight / self.image.size.height;
    CGFloat downscaleWidth = lineFrag.size.width / self.image.size.width;
    CGFloat downscale = MIN(downscaleWidth, downscaleHeight);
    
    if (downscale >= 1.0) {
        // Our image will fit as is
        [self setImageScale:1.0];
        return [super attachmentBoundsForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];
    }
    
    [self setImageScale:downscale];
    
    CGRect bounds = CGRectIntegral(CGRectMake(0.0, 0.0, self.image.size.width * downscale, self.image.size.height * downscale));
    ZNGLogDebug(@"Returning %@ as bounds for a %@", NSStringFromCGRect(bounds), [self class]);
    return bounds;
}

@end
