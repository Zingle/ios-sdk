//
//  ZNGBubbleImage.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "ZNGMessageBubbleImageDataSource.h"

/**
 *  A `ZNGBubbleImage` model object represents a message bubble image, and is immutable. 
 *  This is a concrete class that implements the `ZNGMessageBubbleImageDataSource` protocol.
 *  It contains a regular message bubble image and a highlighted message bubble image.
 *
 *  @see ZNGBubbleImageFactory.
 */
@interface ZNGBubbleImage : NSObject <ZNGMessageBubbleImageDataSource, NSCopying>

/**
 *  Returns the message bubble image for a regular display state.
 */
@property (strong, nonatomic, readonly) UIImage *messageBubbleImage;

/**
 *  Returns the message bubble image for a highlighted display state.
 */
@property (strong, nonatomic, readonly) UIImage *messageBubbleHighlightedImage;

/**
 *  Initializes and returns a message bubble image object having the specified regular image and highlighted image.
 *
 *  @param image            The regular message bubble image. This value must not be `nil`.
 *  @param highlightedImage The highlighted message bubble image. This value must not be `nil`.
 *
 *  @return An initialized `ZNGBubbleImage` object if successful, `nil` otherwise.
 *
 *  @see ZNGBubbleImageFactory.
 */
- (instancetype)initWithMessageBubbleImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage;

@end
