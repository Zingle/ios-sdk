//
//  UIFont+Lato.m
//  Zingle
//
//  Created by Jason Neel on 8/4/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import "UIFont+Lato.h"
#import "ZingleSDK.h"
#import "ZNGLogging.h"
@import CoreText;

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation UIFont (Lato)

+ (void) load
{
    NSArray<NSData *> * fontDataArray = @[
                                          [self fontDataForFont:@"Lato-Regular"],
                                          [self fontDataForFont:@"Lato-Semibold"],
                                          [self fontDataForFont:@"Lato-Bold"]
                                          ];

    for (NSData * fontData in fontDataArray) {
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)fontData);
        CGFontRef font = CGFontCreateWithDataProvider(provider);
        CFErrorRef error;
        
        if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
            CFStringRef errorDescription = CFErrorCopyDescription(error);
            ZNGLogError(@"Unable to load Lato font data");
            CFRelease(errorDescription);
        }
        
        CFRelease(font);
        CFRelease(provider);
    }
}

+ (NSData *) fontDataForFont:(NSString *)fontName
{
    NSBundle * bundle = [NSBundle bundleForClass:[ZingleSDK class]];
    NSString * path = [bundle pathForResource:fontName ofType:@"ttf"];
    NSData * fontData = nil;
    
    if (path != nil) {
        fontData = [NSData dataWithContentsOfFile:path];
    }
    
    if (fontData != nil) {
        return fontData;
    }
    
    return nil;
}

+ (UIFont *) latoFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"Lato-Regular" size:size];
}

+ (UIFont  *) latoSemiBoldFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"Lato-Semibold" size:size];
}

+ (UIFont *) latoBoldFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"Lato-Bold" size:size];
}

@end
