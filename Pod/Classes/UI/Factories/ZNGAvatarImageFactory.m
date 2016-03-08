
#import "ZNGAvatarImageFactory.h"

#import "UIColor+ZingleSDK.h"


@interface ZNGAvatarImageFactory ()

+ (UIImage *)zng_circularImage:(UIImage *)image
                  withDiameter:(NSUInteger)diameter
              highlightedColor:(UIColor *)highlightedColor;

+ (UIImage *)zng_imageWitInitials:(NSString *)initials
                  backgroundColor:(UIColor *)backgroundColor
                        textColor:(UIColor *)textColor
                             font:(UIFont *)font
                         diameter:(NSUInteger)diameter;

@end



@implementation ZNGAvatarImageFactory

#pragma mark - Public

+ (ZNGAvatarImage *)avatarImageWithPlaceholder:(UIImage *)placeholderImage diameter:(NSUInteger)diameter
{
    UIImage *circlePlaceholderImage = [ZNGAvatarImageFactory zng_circularImage:placeholderImage
                                                                          withDiameter:diameter
                                                                      highlightedColor:nil];

    return [ZNGAvatarImage avatarImageWithPlaceholder:circlePlaceholderImage];
}

+ (ZNGAvatarImage *)avatarImageWithImage:(UIImage *)image diameter:(NSUInteger)diameter
{
    UIImage *avatar = [ZNGAvatarImageFactory circularAvatarImage:image withDiameter:diameter];
    UIImage *highlightedAvatar = [ZNGAvatarImageFactory circularAvatarHighlightedImage:image withDiameter:diameter];

    return [[ZNGAvatarImage alloc] initWithAvatarImage:avatar
                                              highlightedImage:highlightedAvatar
                                              placeholderImage:avatar];
}

+ (UIImage *)circularAvatarImage:(UIImage *)image withDiameter:(NSUInteger)diameter
{
    return [ZNGAvatarImageFactory zng_circularImage:image
                                               withDiameter:diameter
                                           highlightedColor:nil];
}

+ (UIImage *)circularAvatarHighlightedImage:(UIImage *)image withDiameter:(NSUInteger)diameter
{
    return [ZNGAvatarImageFactory zng_circularImage:image
                                               withDiameter:diameter
                                           highlightedColor:[UIColor colorWithWhite:0.1f alpha:0.3f]];
}

+ (ZNGAvatarImage *)avatarImageWithUserInitials:(NSString *)userInitials
                                        backgroundColor:(UIColor *)backgroundColor
                                              textColor:(UIColor *)textColor
                                                   font:(UIFont *)font
                                               diameter:(NSUInteger)diameter
{
    UIImage *avatarImage = [ZNGAvatarImageFactory zng_imageWitInitials:userInitials
                                                               backgroundColor:backgroundColor
                                                                     textColor:textColor
                                                                          font:font
                                                                      diameter:diameter];

    UIImage *avatarHighlightedImage = [ZNGAvatarImageFactory zng_circularImage:avatarImage
                                                                          withDiameter:diameter
                                                                      highlightedColor:[UIColor colorWithWhite:0.1f alpha:0.3f]];

    return [[ZNGAvatarImage alloc] initWithAvatarImage:avatarImage
                                              highlightedImage:avatarHighlightedImage
                                              placeholderImage:avatarImage];
}

#pragma mark - Private

+ (UIImage *)zng_imageWitInitials:(NSString *)initials
                  backgroundColor:(UIColor *)backgroundColor
                        textColor:(UIColor *)textColor
                             font:(UIFont *)font
                         diameter:(NSUInteger)diameter
{
    NSParameterAssert(initials != nil);
    NSParameterAssert(backgroundColor != nil);
    NSParameterAssert(textColor != nil);
    NSParameterAssert(font != nil);
    NSParameterAssert(diameter > 0);

    CGRect frame = CGRectMake(0.0f, 0.0f, diameter, diameter);

    NSDictionary *attributes = @{ NSFontAttributeName : font,
                                  NSForegroundColorAttributeName : textColor };

    CGRect textFrame = [initials boundingRectWithSize:frame.size
                                              options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                           attributes:attributes
                                              context:nil];

    CGPoint frameMidPoint = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    CGPoint textFrameMidPoint = CGPointMake(CGRectGetMidX(textFrame), CGRectGetMidY(textFrame));

    CGFloat dx = frameMidPoint.x - textFrameMidPoint.x;
    CGFloat dy = frameMidPoint.y - textFrameMidPoint.y;
    CGPoint drawPoint = CGPointMake(dx, dy);
    UIImage *image = nil;

    UIGraphicsBeginImageContextWithOptions(frame.size, NO, [UIScreen mainScreen].scale);
    {
        CGContextRef context = UIGraphicsGetCurrentContext();

        CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
        CGContextFillRect(context, frame);
        [initials drawAtPoint:drawPoint withAttributes:attributes];

        image = UIGraphicsGetImageFromCurrentImageContext();

    }
    UIGraphicsEndImageContext();

    return [ZNGAvatarImageFactory zng_circularImage:image withDiameter:diameter highlightedColor:nil];
}

+ (UIImage *)zng_circularImage:(UIImage *)image withDiameter:(NSUInteger)diameter highlightedColor:(UIColor *)highlightedColor
{
    NSParameterAssert(image != nil);
    NSParameterAssert(diameter > 0);

    CGRect frame = CGRectMake(0.0f, 0.0f, diameter, diameter);
    UIImage *newImage = nil;

    UIGraphicsBeginImageContextWithOptions(frame.size, NO, [UIScreen mainScreen].scale);
    {
        CGContextRef context = UIGraphicsGetCurrentContext();

        UIBezierPath *imgPath = [UIBezierPath bezierPathWithOvalInRect:frame];
        [imgPath addClip];
        [image drawInRect:frame];

        if (highlightedColor != nil) {
            CGContextSetFillColorWithColor(context, highlightedColor.CGColor);
            CGContextFillEllipseInRect(context, frame);
        }

        newImage = UIGraphicsGetImageFromCurrentImageContext();
        
    }
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
