//
//  ZNGInitialsAvatar.h
//  Pods
//
//  Created by Jason Neel on 12/21/16.
//
//

#import <Foundation/Foundation.h>
#import "JSQMessagesViewController/JSQMessageAvatarImageDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZNGInitialsAvatar : NSObject <JSQMessageAvatarImageDataSource>

+ (instancetype) new NS_UNAVAILABLE;
- (id) init NS_UNAVAILABLE;

- (id) initWithInitials:(NSString *)initials textColor:(UIColor *)textColor backgroundColor:(UIColor *)backgroundColor size:(CGSize)size font:(UIFont *)font;

@property (nonatomic, readonly) NSString * initials;
@property (nonatomic, readonly) UIColor * textColor;
@property (nonatomic, readonly) UIColor * backgroundColor;
@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) UIFont * font;

NS_ASSUME_NONNULL_END

@end
