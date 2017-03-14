//
//  ZNGImageAvatar.h
//  Pods
//
//  Created by Jason Neel on 1/11/17.
//
//

#import <Foundation/Foundation.h>
#import "JSQMessagesViewController/JSQMessageAvatarImageDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZNGImageAvatar : NSObject <JSQMessageAvatarImageDataSource>

/**
 *  Creates an avatar with the specified image centered within the given size.  Note that the image will never be resized.
 */
- (id) initWithImage:(UIImage *)image backgroundColor:(nullable UIColor *)backgroundColor size:(CGSize)size;

/**
 *  The image to be centered within the avatar.  If backgroundColor is not nil and not [UIColor clearColor], the image will be drawn in the center of a circle of the background color.
 */
@property (nonatomic, strong, nonnull) UIImage * image;

/**
 *  The color of the background behind the provided image.  If this is nil, the image itself will be used without any resizing or drawing.
 */
@property (nonatomic, strong, nullable) UIColor * backgroundColor;

@property (nonatomic, assign) CGSize size;

NS_ASSUME_NONNULL_END

@end
