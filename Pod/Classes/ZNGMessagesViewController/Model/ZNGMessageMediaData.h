//
//  ZNGMessageMediaData.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  The `ZNGMessageMediaData` protocol defines the common interface through which
 *  a `ZNGMessagesViewController` and `ZNGMessagesCollectionView` interact with media message model objects.
 *
 *  It declares the required and optional methods that a class must implement so that instances of that class
 *  can be displayed properly within a `ZNGMessagesCollectionViewCell`.
 *
 *  This library provides a few concrete classes that conform to this protocol. You may use them as-is,
 *  but they will likely require some modifications or extensions to conform to your particular data models.
 *  These concrete media items are: `ZNGPhotoMediaItem`, `ZNGLocationMediaItem`, `ZNGVideoMediaItem`.
 *
 *  @see ZNGPhotoMediaItem.
 *  @see ZNGLocationMediaItem.
 *  @see ZNGVideoMediaItem.
 */
@protocol ZNGMessageMediaData <NSObject>

@required

/**
 *  @return An initialized `UIView` object that represents the data for this media object.
 *
 *  @discussion You may return `nil` from this method while the media data is being downloaded.
 */
- (UIView *)mediaView;

/**
 *  @return The frame size for the mediaView when displayed in a `ZNGMessagesCollectionViewCell`. 
 *
 *  @discussion You should return an appropriate size value to be set for the mediaView's frame
 *  based on the contents of the view, and the frame and layout of the `ZNGMessagesCollectionViewCell`
 *  in which mediaView will be displayed.
 *
 *  @warning You must return a size with non-zero, positive width and height values.
 */
- (CGSize)mediaViewDisplaySize;

/**
 *  @return A placeholder media view to be displayed if mediaView is not yet available, or `nil`.
 *  For example, if mediaView will be constructed based on media data that must be downloaded,
 *  this placeholder view will be used until mediaView is not `nil`.
 *
 *  @discussion If you do not need support for a placeholder view, then you may simply return the
 *  same value here as mediaView. Otherwise, consider using `ZNGMessagesMediaPlaceholderView`.
 *
 *  @warning You must not return `nil` from this method.
 *
 *  @see ZNGMessagesMediaPlaceholderView.
 */
- (UIView *)mediaPlaceholderView;

/**
 *  @return An integer that can be used as a table address in a hash table structure.
 *
 *  @discussion This value must be unique for each media item with distinct contents.
 *  This value is used to cache layout information in the collection view.
 */
- (NSUInteger)mediaHash;

@end
