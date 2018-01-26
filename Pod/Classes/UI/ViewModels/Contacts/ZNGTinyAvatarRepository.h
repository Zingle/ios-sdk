//
//  ZNGTinyAvatarRepository.h
//  ZingleSDK
//
//  Created by Jason Neel on 1/25/18.
//

#import <Foundation/Foundation.h>

@class ZNGUser;

@interface ZNGTinyAvatarRepository : NSObject

- (id _Nonnull) initWithAvatarDiameter:(CGFloat)diameter;

/**
 *  If an avatar for this user has been fetched already, it is immediately returned here.
 *  Otherwise, nil is returned.  Note that this does *not* then fetch the avatar.
 *  `fetchTinyAvatarForUser:completion:` must be called to fetch the avatar for future calls.
 */
- (UIImage * _Nullable) tinyAvatarForUser:(ZNGUser * _Nonnull)user;

/**
 *  Fetches the avatar for the provided user.  The completion block is called at the end of the current run loop
 *   if the avatar is already available.
 */
- (void) fetchTinyAvatarForUser:(ZNGUser * _Nonnull)user completion:(void (^ _Nullable)(UIImage * _Nullable avatar))completion;

@end
