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

/**
 *  @return A color object containing HSB values similar to the Zingle dashboard light gray bubble color.
 */
+ (UIColor *)zng_messageBubbleLightGrayColor;

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