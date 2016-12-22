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

- (id) initWithInitials:(NSString *)initials textColor:(UIColor *)textColor backgroundColor:(UIColor *)backgroundColor size:(CGSize)size
{
    self = [super init];
    
    if (self != nil) {
        // TODO: Actually render the initials
        
        CGRect rect = CGRectMake(0.0, 0.0, size.width, size.height);
        UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef context = UIGraphicsGetCurrentContext();
     
        CGContextSetFillColorWithColor(context, [backgroundColor CGColor]);
        CGContextFillEllipseInRect(context, rect);
        
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
