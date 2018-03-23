//
//  ZNGPlaceholderImageAttachment.m
//  Pods
//
//  Created by Jason Neel on 1/9/17.
//
//

#import "ZNGPlaceholderImageAttachment.h"

@import SBObjectiveCWrapper;

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
        
        CGSize size = theImageSize;
        
        if (CGSizeEqualToSize(size, CGSizeZero)) {
            size = kDefaultPlaceholderSize;
        }
        
        imageSize = size;
        _backgroundColor = [UIColor clearColor];
        
        NSBundle * bundle = [NSBundle bundleForClass:[ZNGPlaceholderImageAttachment class]];
        _iconImage = [[UIImage imageNamed:@"attachment" inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        _iconTintColor = [UIColor grayColor];
        
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

- (void) setIconTintColor:(UIColor *)iconTintColor
{
    _iconTintColor = iconTintColor;
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
    if ((self.iconImage != nil) && (self.iconTintColor != nil)) {
        CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));

        // Translate our origin to the bottom left corner of where we want the image in our center
        CGContextTranslateCTM(context, center.x - (self.iconImage.size.width * 0.5), center.y + (self.iconImage.size.height * 0.5));
        
        // Flip our scale since BMPs love being upside down
        CGContextScaleCTM(context, 1.0, -1.0);
        
        // Apply image as a mask
        CGContextClipToMask(context, CGRectMake(0.0, 0.0, self.iconImage.size.width, self.iconImage.size.height), [self.iconImage CGImage]);

        // Fill the masked space
        [self.iconTintColor setFill];
        CGContextFillRect(context, rect);
        
        // Drink a beer.
    }
    
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    SBLogDebug(@"Rendered a %@ placeholder image", NSStringFromCGSize(self.image.size));
    
    UIGraphicsEndImageContext();
}

- (CGRect) attachmentBoundsForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex
{
    if ((imageSize.height == 0) || (imageSize.width == 0)) {
        CGRect bounds = [super attachmentBoundsForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];
        SBLogDebug(@"Returning %@ as bounds for a %@", NSStringFromCGRect(bounds), [self class]);
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
    SBLogDebug(@"Returning %@ as bounds for a %@", NSStringFromCGRect(bounds), [self class]);
    return bounds;
}

@end
