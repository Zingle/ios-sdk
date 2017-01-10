//
//  ZNGPlaceholderImageAttachment.m
//  Pods
//
//  Created by Jason Neel on 1/9/17.
//
//

#import "ZNGPlaceholderImageAttachment.h"
#import "ZNGLogging.h"

static const int zngLogLevel = ZNGLogLevelDebug;

#define kDefaultPlaceholderSize CGSizeMake(250.0, 250.0)

@implementation ZNGPlaceholderImageAttachment
{
    CGSize imageSize;
}

- (id) init
{
    return [self initWithSize:kDefaultPlaceholderSize];
}

- (id) initWithSize:(CGSize)theImageSize
{
    self = [super init];
    
    if (self != nil) {
        imageSize = theImageSize;
        _backgroundColor = [UIColor lightGrayColor];
//        _iconTintColor = [UIColor grayColor];
        
        NSBundle * bundle = [NSBundle bundleForClass:[ZNGPlaceholderImageAttachment class]];
        _iconImage = [[UIImage imageNamed:@"attachImage" inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        [self renderPlaceholder];
    }
    
    return self;
}

- (void) setImageScale:(CGFloat)imageScale
{
    if (_imageScale == imageScale) {
        return;
    }
    
    _imageScale = imageScale;
    
    [self renderPlaceholder];
}

- (void) setBackgroundColor:(UIColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    [self renderPlaceholder];
}

- (void) setIconImage:(UIImage *)iconImage
{
    _iconImage = iconImage;
    [self renderPlaceholder];
}

- (void) renderPlaceholder
{
    // Ensure we don't end up with a silly scale like 0% or 200%.  We want (0.0, 1.0]
    BOOL imageScaleIsNormalized = ((self.imageScale > 0.0) && (self.imageScale <= 1.0));
    CGFloat scale = (imageScaleIsNormalized) ? self.imageScale : 1.0;
 
    CGFloat width = imageSize.width * scale;
    CGFloat height = imageSize.height * scale;
    CGSize size = CGSizeMake(width, height);
    CGRect rect = CGRectMake(0.0, 0.0, width, height);
    
    UIColor * backgroundColor = self.backgroundColor ?: [UIColor clearColor];
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Background
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context, kCGPathFill);
    
    // Placeholder icon
    if (self.iconImage != nil) {
        CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
        CGRect placeholderRect = CGRectIntegral(CGRectMake(center.x - (self.iconImage.size.width * 0.5), center.y - (self.iconImage.size.height * 0.5), self.iconImage.size.width, self.iconImage.size.height));
        [self.iconImage drawInRect:placeholderRect];
    }
    
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    ZNGLogDebug(@"Rendered a %@ placeholder image", NSStringFromCGSize(self.image.size));
    
    UIGraphicsEndImageContext();
}

- (CGRect) attachmentBoundsForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex
{
    if ((imageSize.height == 0) || (imageSize.width == 0)) {
        CGRect bounds = [super attachmentBoundsForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];
        ZNGLogDebug(@"Returning %@ as bounds for a %@", NSStringFromCGRect(bounds), [self class]);
        return bounds;
    }
    
    CGFloat downscaleHeight = self.maxDisplayHeight / imageSize.height;
    CGFloat downscaleWidth = lineFrag.size.width / imageSize.width;
    
    if ((downscaleHeight >= 1.0) && (downscaleWidth >= 1.0)) {
        // Our image will fit as is
        [self setImageScale:1.0];
        return [super attachmentBoundsForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];
    }
    
    CGFloat downscale = MIN(downscaleWidth, downscaleHeight);
    
    [self setImageScale:downscale];
    
    CGRect bounds = CGRectIntegral(CGRectMake(0.0, 0.0, self.image.size.width, self.image.size.height));
    ZNGLogDebug(@"Returning %@ as bounds for a %@", NSStringFromCGRect(bounds), [self class]);
    return bounds;
}

@end
