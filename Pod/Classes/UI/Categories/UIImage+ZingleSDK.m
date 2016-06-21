

#import "UIImage+ZingleSDK.h"
#import "ZingleSDK.h"

@implementation UIImage (ZingleSDK)

- (UIImage *)zng_imageMaskedWithColor:(UIColor *)maskColor
{
    NSParameterAssert(maskColor != nil);
    
    CGRect imageRect = CGRectMake(0.0f, 0.0f, self.size.width, self.size.height);
    UIImage *newImage = nil;
    
    UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, self.scale);
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextScaleCTM(context, 1.0f, -1.0f);
        CGContextTranslateCTM(context, 0.0f, -(imageRect.size.height));
        
        CGContextClipToMask(context, imageRect, self.CGImage);
        CGContextSetFillColorWithColor(context, maskColor.CGColor);
        CGContextFillRect(context, imageRect);
        
        newImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage *)zng_bubbleImageFromBundleWithName:(NSString *)name
{
    NSBundle *bundle = [NSBundle bundleForClass:[ZingleSDK class]];
    return [[UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAutomatic];
}

+ (UIImage *)zng_bubbleRegularImage
{
    return [UIImage zng_bubbleImageFromBundleWithName:@"bubble_regular"];
}

+ (UIImage *)zng_bubbleRegularTaillessImage
{
    return [UIImage zng_bubbleImageFromBundleWithName:@"bubble_tailless"];
}

+ (UIImage *)zng_bubbleRegularStrokedImage
{
    return [UIImage zng_bubbleImageFromBundleWithName:@"bubble_stroked"];
}

+ (UIImage *)zng_bubbleRegularStrokedTaillessImage
{
    return [UIImage zng_bubbleImageFromBundleWithName:@"bubble_stroked_tailless"];
}

+ (UIImage *)zng_bubbleCompactImage
{
    UIImage *image = [UIImage zng_bubbleImageFromBundleWithName:@"bubble_min"];
    return image;
}

+ (UIImage *)zng_bubbleCompactTaillessImage
{
    return [UIImage zng_bubbleImageFromBundleWithName:@"bubble_min_tailless"];
}

+ (UIImage *)zng_defaultAccessoryImage
{
    UIImage *image = [UIImage zng_bubbleImageFromBundleWithName:@"clip"];
    return image;
}

+ (UIImage *)zng_addItemImage
{
    UIImage *image = [UIImage zng_bubbleImageFromBundleWithName:@"add"];
    return image;
}

+ (UIImage *)zng_defaultTypingIndicatorImage
{
    return [UIImage zng_bubbleImageFromBundleWithName:@"typing"];
}

+ (UIImage *)zng_defaultPlayImage
{
    return [UIImage zng_bubbleImageFromBundleWithName:@"play"];
}

+ (UIImage *)zng_starredImage
{
    return [UIImage zng_bubbleImageFromBundleWithName:@"starred"];
}

+ (UIImage *)zng_unstarredImage
{
    return [UIImage zng_bubbleImageFromBundleWithName:@"unstarred"];
}

+ (UIImage *)zng_lrg_starredImage
{
    return [UIImage zng_bubbleImageFromBundleWithName:@"lrg_starred"];
}

+ (UIImage *)zng_lrg_unstarredImage
{
    return [UIImage zng_bubbleImageFromBundleWithName:@"lrg_unstarred"];
}

+ (UIImage *)zng_confirmedImage
{
    return [UIImage zng_bubbleImageFromBundleWithName:@"confirmed"];
}

+ (UIImage *)zng_unconfirmedImage
{
    return [UIImage zng_bubbleImageFromBundleWithName:@"unconfirmed"];
}

@end
