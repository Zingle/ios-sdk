//
//  UIColor+ZingleSDK.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (ZingleSDK)

#pragma mark - Message bubble colors

+ (UIColor *)zng_unconfirmedMessageGreen;

+ (UIColor *)zng_unconfirmedMessageRed;

+ (UIColor *)zng_errorMessageBackgroundColor;

/**
 *  @return A color object containing HSB values similar to the Zingle dashboard light gray bubble color.
 */
+ (UIColor *)zng_messageBubbleLightGrayColor;

+ (UIColor *)zng_titleBlack;

+ (UIColor *)zng_blue;

+ (UIColor *)zng_lightBlue;

+ (UIColor *)zng_purple;

+ (UIColor *)zng_green;

+ (UIColor *)zng_gray;

+ (UIColor *)zng_light_gray;

+ (UIColor *)zng_text_gray;

+ (UIColor *)zng_yellow;

+ (UIColor *)zng_note_yellow;

+ (UIColor *)zng_strawberry;

+ (UIColor *) zng_loadingGradientInnerColor;

+ (UIColor *) zng_loadingGradientOuterColor;

/**
 *  Creates and returns a new color object from a hex color value.
 *
 *  @param hexString A string hex value example: #D4D4D4
 *
 *  @return A new color object matching a the RGB hex value.
 */
+ (UIColor * _Nullable)colorFromHexString:(NSString *)hexString;

#pragma mark - Utilities

- (UIColor *)zng_colorByLighteningColor:(CGFloat)light;

/**
 *  Creates and returns a new color object whose brightness component is decreased by the given value, using the initial color values of the receiver.
 *
 *  @param value A floating point value describing the amount by which to decrease the brightness of the receiver.
 *
 *  @return A new color object whose brightness is decreased by the given values. The other color values remain the same as the receiver.
 */
- (UIColor *)zng_colorByDarkeningColorWithValue:(CGFloat)value;

@end

NS_ASSUME_NONNULL_END
