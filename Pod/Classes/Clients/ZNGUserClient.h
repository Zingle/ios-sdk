//
//  ZNGUserClient.h
//  Pods
//
//  Created by Jason Neel on 4/5/17.
//
//

#import <ZingleSDK/ZNGBaseClientAccount.h>

NS_ASSUME_NONNULL_BEGIN

@class ZNGUser;
@class ZNGUserV2;

@interface ZNGUserClient : ZNGBaseClientAccount

- (void) userWithId:(NSString *)userId
            success:(void (^)(ZNGUser* user, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure;

- (void) getAllUsersInServiceId:(NSString *)serviceId
                        success:(void (^)(NSArray<ZNGUserV2 *> * users))success
                        failure:(void (^ _Nullable)(ZNGError * error))failure;

#pragma mark - Avatars
- (void) deleteAvatarForUserWithId:(NSString *)userId
                           success:(void (^ _Nullable)(void))success
                           failure:(void (^ _Nullable)(ZNGError * error))failure;

- (void) uploadAvatar:(UIImage *)avatarImage
        forUserWithId:(NSString *)userId
              success:(void (^ _Nullable)(void))success
              failure:(void (^ _Nullable)(ZNGError * error))failure;

NS_ASSUME_NONNULL_END
                                    
@end
