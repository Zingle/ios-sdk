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
 *  Returns an avatar image of the user's initials, either for an employee or a contact.  Results are cached and reused via provided UUID.
 */
- (nullable id <JSQMessageAvatarImageDataSource>) avatarForUserUUID:(NSString *)uuid name:(NSString *)name outgoing:(BOOL)isOutgoing;

@property (nonatomic, strong, nullable) UIColor * outgoingBackgroundColor;
@property (nonatomic, strong, nullable) UIColor * outgoingTextColor;
@property (nonatomic, strong, nullable) UIColor * incomingBackgroundColor;
@property (nonatomic, strong, nullable) UIColor * incomingTextColor;
@property (nonatomic, assign) CGSize avatarSize;

NS_ASSUME_NONNULL_END

@end
