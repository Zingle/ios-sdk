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
 *  The padding to place around the view when showEditIcon is set to YES.  Note all numbers should be negative or 0.0
 */
@property (nonatomic, assign) UIEdgeInsets insetsWhenEditIconPresent;

/**
 *  Corresponding read/write property to center, taking into account any edit icon and its corresponding offset on our image.
 *  Setting this property does not move the image within our view; it moves the view itself to position the image as specified in our superview.
 */
@property (nonatomic, assign) CGPoint centerOfImage;

// Readonly properties set on init
@property (nonatomic, readonly, nullable) NSURL * avatarUrl;
@property (nonatomic, readonly) NSString * initials;
@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly, nullable) UIColor * backgroundColor;
@property (nonatomic, readonly) UIColor * textColor;
@property (nonatomic, readonly) UIFont * font;
@property (nonatomic, readonly) UIImage * placeholderImage;

- (id) initWithAvatarUrl:(NSURL * _Nullable)avatarUrl initials:(NSString * _Nullable)initials size:(CGSize)size backgroundColor:(UIColor * _Nullable)backgroundColor textColor:(UIColor *)textColor font:(UIFont *)font;

/**
 *  Can be overridden by subclasses to move the edit icon from its default position of lower right.
 */
- (CGPoint) editImageLocation;

NS_ASSUME_NONNULL_END

@end
