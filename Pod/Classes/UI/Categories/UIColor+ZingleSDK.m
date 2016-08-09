
#import "UIColor+ZingleSDK.h"

@implementation UIColor (ZingleSDK)

#pragma mark - Message bubble colors

+ (UIColor *)zng_messageBubbleGreenColor
{
    return [UIColor colorWithHue:130.0f / 360.0f
                      saturation:0.68f
                      brightness:0.84f
                           alpha:1.0f];
}

+ (UIColor *)zng_messageBubbleBlueColor
{
    return [UIColor colorWithRed:229.0f/255.0f
                           green:245.0f/255.0f
                            blue:252.0f/255.0f
                           alpha:1.0f];
}

+ (UIColor *)zng_messageBubbleRedColor
{
    return [UIColor colorWithHue:0.0f / 360.0f
                      saturation:0.79f
                      brightness:1.0f
                           alpha:1.0f];
}

+ (UIColor *)zng_messageBubbleLightGrayColor
{
    return [UIColor colorWithRed:225.0f/255.0f
                           green:225.0f/255.0f
                            blue:225.0f/255.0f
                           alpha:1.0f];
}

+ (UIColor *)zng_unconfirmedMessageGreen
{
    return [UIColor colorFromHexString:@"#6CDB9B"];
}

+ (UIColor *)zng_unconfirmedMessageRed
{
    return [UIColor colorFromHexString:@"#EE8176"];
}

+ (UIColor *)zng_blue
{
    return [UIColor colorFromHexString:@"#285C8C"];
}

+ (UIColor *)zng_lightBlue
{
    return [UIColor colorFromHexString:@"#00a1df"];
}

+ (UIColor *)zng_lighterBlue
{
    return [UIColor colorFromHexString:@"#7ADDFF"];
}

+ (UIColor *)zng_green
{
    return [UIColor colorFromHexString:@"#02CE68"];
}

+ (UIColor *)zng_gray
{
    return [UIColor colorFromHexString:@"#B6B8BA"];
}

+ (UIColor *)zng_yellow
{
    return [UIColor colorFromHexString:@"#FFCF3A"];
}


+ (UIColor *)colorFromHexString:(NSString *)hexString
{
    if (hexString == nil) {
        return nil;
    }
    
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

#pragma mark - Utilities

- (UIColor *)zng_colorByDarkeningColorWithValue:(CGFloat)value
{
    NSUInteger totalComponents = CGColorGetNumberOfComponents(self.CGColor);
    BOOL isGreyscale = (totalComponents == 2) ? YES : NO;
    
    CGFloat *oldComponents = (CGFloat *)CGColorGetComponents(self.CGColor);
    CGFloat newComponents[4];
    
    if (isGreyscale) {
        newComponents[0] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[1] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[2] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[3] = oldComponents[1];
    }
    else {
        newComponents[0] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[1] = oldComponents[1] - value < 0.0f ? 0.0f : oldComponents[1] - value;
        newComponents[2] = oldComponents[2] - value < 0.0f ? 0.0f : oldComponents[2] - value;
        newComponents[3] = oldComponents[3];
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorRef newColor = CGColorCreate(colorSpace, newComponents);
	CGColorSpaceRelease(colorSpace);
    
	UIColor *retColor = [UIColor colorWithCGColor:newColor];
	CGColorRelease(newColor);
    
    return retColor;
}

@end