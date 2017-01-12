//
//  ZNGAvatarCache.h
//  Pods
//
//  Created by Jason Neel on 12/21/16.
//
//

#import <Foundation/Foundation.h>
#import "JSQMessagesViewController/JSQMessageAvatarImageDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@class ZNGParticipant;

@interface ZNGAvatarCache : NSObject

+ (instancetype) sharedCache;

/**
 *  Returns a cached avatar for this user if available, otherwise an avatar using the provided image.
 *
 *  @param circleBackground If this is set, the supplied image is drawn over a circle similar to an initials avatar.  Otherwise, the raw image is used (sized appropriately.)
 */
- (id <JSQMessageAvatarImageDataSource>) avatarForUserUUID:(NSString *)uuid image:(UIImage *)image useCircleBackground:(BOOL)circleBackground outgoing:(BOOL)isOutgoing;

/**
 *  Returns an avatar image of the user's initials, either for an employee or a contact.  Results are cached and reused via provided UUID.
 */
- (id <JSQMessageAvatarImageDataSource>) avatarForUserUUID:(NSString *)uuid name:(NSString *)name outgoing:(BOOL)isOutgoing;

@property (nonatomic, strong, nullable) UIColor * outgoingBackgroundColor;
@property (nonatomic, strong, nullable) UIColor * outgoingTextColor;
@property (nonatomic, strong, nullable) UIColor * incomingBackgroundColor;
@property (nonatomic, strong, nullable) UIColor * incomingTextColor;
@property (nonatomic, strong, nullable) UIFont * font;
@property (nonatomic, assign) CGSize avatarSize;

NS_ASSUME_NONNULL_END

@end
