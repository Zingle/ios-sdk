//
//  ZNGMessageBubbleImageDataSource.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  The `ZNGMessageBubbleImageDataSource` protocol defines the common interface through which
 *  a `ZNGMessagesViewController` and `ZNGMessagesCollectionView` interact with 
 *  message bubble image model objects.
 *
 *  It declares the required and optional methods that a class must implement so that instances
 *  of that class can be display properly within a `ZNGMessagesCollectionViewCell`.
 *
 *  A concrete class that conforms to this protocol is provided in the library. See `ZNGMessagesBubbleImage`.
 *
 *  @see ZNGMessagesBubbleImage.
 */
@protocol ZNGMessageBubbleImageDataSource <NSObject>

@required

/**
 *  @return The message bubble image for a regular display state.
 *
 *  @warning You must not return `nil` from this method.
 */
- (UIImage *)messageBubbleImage;

/**
 *  @return The message bubble image for a highlighted display state.
 *
 *  @warning You must not return `nil` from this method.
 */
- (UIImage *)messageBubbleHighlightedImage;

@end
