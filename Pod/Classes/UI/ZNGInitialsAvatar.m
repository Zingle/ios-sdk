//
//  ZNGInitialsAvatar.m
//  Pods
//
//  Created by Jason Neel on 12/21/16.
//
//

#import "ZNGInitialsAvatar.h"

@implementation ZNGInitialsAvatar
{
    UIImage * image;
}

- (id) initWithInitials:(NSString *)initials textColor:(UIColor *)textColor backgroundColor:(UIColor *)backgroundColor size:(CGSize)size font:(UIFont *)font
{
    self = [super init];
    
    if (self != nil) {
        CGRect rect = CGRectMake(0.0, 0.0, size.width, size.height);
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
     
        CGContextSetFillColorWithColor(context, [backgroundColor CGColor]);
        CGContextFillEllipseInRect(context, rect);
        
        NSDictionary * textAttributes = @{ NSFontAttributeName: font, NSForegroundColorAttributeName : textColor };
        CGSize initialsSize = [initials sizeWithAttributes:textAttributes];
        
        CGFloat heightDifference = rect.size.height - initialsSize.height;
        CGFloat widthDifference = rect.size.width - initialsSize.width;
        CGRect initialsRect = CGRectMake(widthDifference * 0.5, heightDifference * 0.5, rect.size.width - widthDifference, rect.size.height - heightDifference);
        
        [initials drawInRect:initialsRect withAttributes:textAttributes];
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return self;
}

- (UIImage *)avatarImage
{
    return image;
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
