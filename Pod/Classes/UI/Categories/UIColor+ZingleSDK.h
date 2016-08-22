//
//  UIColor+ZingleSDK.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <UIKit/UIKit.h>

@interface UIColor (ZingleSDK)

#pragma mark - Message bubble colors

/**
 *  @return A color object containing HSB values similar to the iOS messages app green bubble color.
 */
+ (UIColor *)zng_messageBubbleGreenColor;

/**
 *  @return A color object containing HSB values similar to the Zingle dashboard blue bubble color.
 */
+ (UIColor *)zng_messageBubbleBlueColor;

/**
 *  @return A color object containing HSB values similar to the iOS red color.
 */
+ (UIColor *)zng_messageBubbleRedColor;

+ (UIColor *)zng_unconfirmedMessageGreen;

+ (UIColor *)zng_unconfirmedMessageRed;

/**
 *  @return A color object containing HSB values similar to the Zingle dashboard light gray bubble color.
 */
+ (UIColor *)zng_messageBubbleLightGrayColor;


+ (UIColor *)zng_blue;

+ (UIColor *)zng_lightBlue;

+ (UIColor *)zng_purple;

+ (UIColor *)zng_green;

+ (UIColor *)zng_gray;

+ (UIColor *)zng_light_gray;

+ (UIColor *)zng_text_gray;

+ (UIColor *)zng_yellow;

+ (UIColor *)zng_note_yellow;

/**
 *  Creates and returns a new color object from a hex color value.
 *
 *  @param value A string hex value example: #D4D4D4
 *
 *  @return A new color object matching a the RGB hex value.
 */
+ (UIColor *)colorFromHexString:(NSString *)hexString;

#pragma mark - Utilities

/**
 *  Creates and returns a new color object whose brightness component is decreased by the given value, using the initial color values of the receiver.
 *
 *  @param value A floating point value describing the amount by which to decrease the brightness of the receiver.
 *
 *  @return A new color object whose brightness is decreased by the given values. The other color values remain the same as the receiver.
 */
- (UIColor *)zng_colorByDarkeningColorWithValue:(CGFloat)value;

@end