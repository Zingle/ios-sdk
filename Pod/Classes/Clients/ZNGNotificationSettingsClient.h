//
//  ZNGNotificationSettingsClient.h
//  ZingleSDK
//
//  Created by Jason Neel on 3/8/18.
//

#import <ZingleSDK/ZingleSDK.h>

@class ZNGNotificationSettings;

@interface ZNGNotificationSettingsClient : ZNGBaseClientService

- (void)notificationSettingsForUserId:(NSString * _Nonnull)userId
                          WithSuccess:(void (^ _Nullable)(ZNGNotificationSettings * _Nonnull notificationSettings))success
                              failure:(void (^ _Nullable)(ZNGError * _Nullable error))failure;

- (void)saveNotificationSettings:(ZNGNotificationSettings * _Nonnull)settings
                       forUserId:(NSString * _Nonnull)userId
                     WithSuccess:(void (^ _Nullable)(void))success
                         failure:(void (^ _Nullable)(ZNGError * _Nullable error))failure;


@end
