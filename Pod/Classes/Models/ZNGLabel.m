//
//  ZNGLabel.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGLabel.h"
#import "ZNGLogging.h"

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGLabel

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"labelId" : @"id",
             @"displayName" : @"display_name",
             @"backgroundColor" : @"background_color",
             @"textColor" : @"text_color",
             @"isGlobal" : @"is_global"
             };
}

// Assumes input like "#00FF00" (#RRGGBB).
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

- (UIColor *)textUIColor
{
    NSString * colorString = self.textColor;
    
    if ([colorString length] == 0) {
        ZNGLogWarn(@"%@ label has no text color information.  Using default #ffffff", self.displayName);
        colorString = @"#ffffff";
    }
    
    return [ZNGLabel colorFromHexString:colorString];
}

- (UIColor *)backgroundUIColor
{
    NSString * colorString = self.backgroundColor;
    
    if ([colorString length] == 0) {
        ZNGLogWarn(@"%@ label has no text color information.  Using default #595959", self.displayName);
        colorString = @"#595959";
    }
    
    return [ZNGLabel colorFromHexString:colorString];
}

@end
