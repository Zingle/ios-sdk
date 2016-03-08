//
//  ZNGBubblesSizeCalculator.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <Foundation/Foundation.h>

#import "ZNGBubbleSizeCalculating.h"

/**
 *  An instance of `ZNGBubblesSizeCalculator` is responsible for calculating
 *  message bubble sizes for an instance of `ZNGCollectionViewFlowLayout`.
 */
@interface ZNGBubblesSizeCalculator : NSObject <ZNGBubbleSizeCalculating>

/**
 *  Initializes and returns a bubble size calculator with the given cache and minimumBubbleWidth.
 *
 *  @param cache                 A cache object used to store layout information.
 *  @param minimumBubbleWidth    The minimum width for any given message bubble.
 *  @param usesFixedWidthBubbles Specifies whether or not to use fixed-width bubbles.
 *  If `NO` (the default), then bubbles will resize when rotating to landscape.
 *
 *  @return An initialized `ZNGBubblesSizeCalculator` object if successful, `nil` otherwise.
 */
- (instancetype)initWithCache:(NSCache *)cache
           minimumBubbleWidth:(NSUInteger)minimumBubbleWidth
        usesFixedWidthBubbles:(BOOL)usesFixedWidthBubbles NS_DESIGNATED_INITIALIZER;

@end
