//
//  ZNGAvatarImageView.h
//  Pods
//
//  Created by Jason Neel on 4/11/17.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Subclass of UIImageView that allows an edit icon to be overlaid onto the image, adjusting intrinsicContentSize to take it into account.
 */
@interface ZNGAvatarImageView : UIImageView

/**
 *  If this flag is set, the edit image will be displayed on the image view, expanding its intrinsicContentSize if necessary.
 */
@property (nonatomic, assign) BOOL showEditIcon;

/**
 *  The image asset to be used as the edit icon
 */
@property (nonatomic, strong, nullable) UIImage * editIconImage;

/**
 *  How far the edit image should extend beyond the normal edges of our image.
 */
@property (nonatomic, assign) CGPoint editImageEdgeOverflow;


- (id) initWithAvatarUrl:(NSURL * _Nullable)avatarUrl initials:(NSString *)initials size:(CGSize)size backgroundColor:(UIColor * _Nullable)backgroundColor textColor:(UIColor *)textColor font:(UIFont *)font;

/**
 *  Can be overridden by subclasses to move the edit icon from its default position of lower right.
 */
- (CGPoint) editImageLocation;

NS_ASSUME_NONNULL_END

@end
