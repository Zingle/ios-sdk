//
//  ZNGInitialsAvatar.h
//  Pods
//
//  Created by Jason Neel on 12/21/16.
//
//

#import <Foundation/Foundation.h>
#import "JSQMessagesViewController/JSQMessageAvatarImageDataSource.h"

@interface ZNGInitialsAvatar : NSObject <JSQMessageAvatarImageDataSource>

+ (instancetype) new NS_UNAVAILABLE;
- (id) init NS_UNAVAILABLE;

- (id) initWithInitials:(NSString *)initials textColor:(UIColor *)textColor backgroundColor:(UIColor *)backgroundColor size:(CGSize)size;

@end
