//
//  UIImage+ZingleSDK.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (ZingleSDK)

/**
 *  Creates and returns a new image object that is masked with the specified mask color.
 *
 *  @param maskColor The color value for the mask. This value must not be `nil`.
 *
 *  @return A new image object masked with the specified color.
 */
- (UIImage *)zng_imageMaskedWithColor:(UIColor *)maskColor;

/**
 *  @return The regular message bubble image.
 */
+ (UIImage *)zng_bubbleRegularImage;

/**
 *  @return The regular message bubble image without a tail.
 */
+ (UIImage *)zng_bubbleRegularTaillessImage;

/**
 *  @return The regular message bubble image stroked, not filled.
 */
+ (UIImage *)zng_bubbleRegularStrokedImage;

/**
 *  @return The regular message bubble image stroked, not filled and without a tail.
 */
+ (UIImage *)zng_bubbleRegularStrokedTaillessImage;

/**
 *  @return The compact message bubble image. 
 *
 *  @disscussion This is the default bubble image used by `ZNGBubbleImageFactory`.
 */
+ (UIImage *)zng_bubbleCompactImage;

/**
 *  @return The compact message bubble image without a tail.
 */
+ (UIImage *)zng_bubbleCompactTaillessImage;

/**
 *  @return The default input toolbar accessory image.
 */
+ (UIImage *)zng_defaultAccessoryImage;

/**
 *  @return The default input toolbar add item image.
 */
+ (UIImage *)zng_addItemImage;

/**
 *  @return The default typing indicator image.
 */
+ (UIImage *)zng_defaultTypingIndicatorImage;

/**
 *  @return The default play icon image.
 */
+ (UIImage *)zng_defaultPlayImage;

/**
 *  @return The star icon.
 */
+ (UIImage *)zng_starredImage;

/**
 *  @return The unfilled star icon.
 */
+ (UIImage *)zng_unstarredImage;

/**
 *  @return The large star icon.
 */
+ (UIImage *)zng_lrg_starredImage;

/**
 *  @return The large unfilled star icon.
 */
+ (UIImage *)zng_lrg_unstarredImage;


@end
