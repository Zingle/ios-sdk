
#import "UIColor+ZingleSDK.h"

@implementation UIColor (ZingleSDK)

#pragma mark - Message bubble colors

+ (UIColor *)zng_errorMessageBackgroundColor
{
    return [UIColor colorFromHexString:@"#2e3c54"];
}

+ (UIColor *)zng_unconfirmedMessageGreen
{
    return [UIColor colorFromHexString:@"#6CDB9B"];
}

+ (UIColor *)zng_unconfirmedMessageRed
{
    return [UIColor colorFromHexString:@"#EE8176"];
}

+ (UIColor *)zng_green
{
    return [UIColor colorFromHexString:@"#02CE68"];
}

+ (UIColor *)zng_light_gray
{
    return [UIColor colorFromHexString:@"#F4F4F4"];
}

+ (UIColor *)zng_text_gray
{
    return [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0f];
}

+ (UIColor *)zng_yellow
{
    return [UIColor colorFromHexString:@"#FFCF3A"];
}

+ (UIColor *)zng_note_yellow
{
    return [UIColor colorFromHexString:@"#EFDAA3"];
}

+ (UIColor *)zng_strawberry
{
    return [UIColor colorFromHexString:@"#E74C3C"];
}


+ (UIColor *)colorFromHexString:(NSString *)hexString
{
    if (hexString == nil) {
        return nil;
    }
    
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner scanString:@"#" intoString:nil];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

#pragma mark - Utilities

- (UIColor *)zng_colorByLighteningColor:(CGFloat)light
{
    CGFloat hue, saturation, brightness, alpha;
    
    if ([self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        brightness += light;
        brightness = MAX(MIN(brightness, 1.0), 0.0);
        
        saturation -= light;
        saturation = MAX(MIN(saturation, 1.0), 0.0);
        return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
    }
    
    return self;
}

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
