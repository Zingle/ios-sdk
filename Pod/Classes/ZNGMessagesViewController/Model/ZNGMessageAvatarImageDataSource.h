//
//  ZNGMessageAvatarImageDataSource.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  The `ZNGMessageAvatarImageDataSource` protocol defines the common interface through which
 *  a `ZNGMessagesViewController` and `ZNGMessagesCollectionView` interact with avatar image model objects.
 *
 *  It declares the required and optional methods that a class must implement so that instances
 *  of that class can be display properly within a `ZNGMessagesCollectionViewCell`.
 *
 *  A concrete class that conforms to this protocol is provided in the library. See `ZNGMessagesAvatarImage`.
 *
 *  @see ZNGMessagesAvatarImage.
 */
@protocol ZNGMessageAvatarImageDataSource <NSObject>

@required

/**
 *  @return The avatar image for a regular display state.
 *  
 *  @discussion You may return `nil` from this method while the image is being downloaded.
 */
- (UIImage *)avatarImage;

/**
 *  @return The avatar image for a highlighted display state. 
 *  
 *  @discussion You may return `nil` from this method if this does not apply.
 */
- (UIImage *)avatarHighlightedImage;

/**
 *  @return A placeholder avatar image to be displayed if avatarImage is not yet available, or `nil`.
 *  For example, if avatarImage needs to be downloaded, this placeholder image
 *  will be used until avatarImage is not `nil`.
 *
 *  @discussion If you do not need support for a placeholder image, that is, your images 
 *  are stored locally on the device, then you may simply return the same value as avatarImage here.
 *
 *  @warning You must not return `nil` from this method.
 */
- (UIImage *)avatarPlaceholderImage;

@end
