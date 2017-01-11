//
//  ZNGPlaceholderImageAttachment.h
//  Pods
//
//  Created by Jason Neel on 1/9/17.
//
//

#import "ZNGImageAttachment.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZNGPlaceholderImageAttachment : ZNGImageAttachment

- (id) initWithSize:(CGSize)imageSize;

- (id) initWithData:(nullable NSData *)contentData ofType:(nullable NSString *)uti NS_UNAVAILABLE;

/**
 *  The color shown behind the small placeholderImage asset before the image has been set.  This can be set to either nil or [UIColor clearColor] for none.
 *
 *  Defaults to [UIColor clearColor];
 */
@property (nonatomic, strong, nullable) UIColor * backgroundColor;

/**
 *  The placeholder image centered within the image bounds before the image property has been set.  Defaults to the "attach image" asset.
 */
@property (nonatomic, strong, nullable) UIImage * iconImage;

///**
// *  Tint color applied to the iconImage.  Defaults to [UIColor grayColor].
// */
@property (nonatomic, strong, nullable) UIColor * iconTintColor;


NS_ASSUME_NONNULL_END

@end
