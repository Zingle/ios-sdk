//
//  ZNGNotificationSettingsClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 3/8/18.
//

#import "ZNGNotificationSettingsClient.h"
#import "ZingleSession.h"
#import "ZNGNotificationSettings.h"

@import AFNetworking;

@implementation ZNGNotificationSettingsClient


- (void)notificationSettingsForUserId:(NSString * _Nonnull)userId
                          WithSuccess:(void (^ _Nullable)(ZNGNotificationSettings * _Nonnull notificationSettings))success
                              failure:(void (^ _Nullable)(ZNGError * _Nullable error))failure
{
    NSString * path = [NSString stringWithFormat:@"notification/%@/preferences", userId];
    
    [self.session.v2SessionManager GET:path parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(self->jsonProcessingQueue, ^{
            NSError * error = nil;
            ZNGNotificationSettings * settings = [MTLJSONAdapter modelOfClass:[ZNGNotificationSettings class] fromJSONDictionary:responseObject error:&error];
            
            if (settings != nil) {
                if (success != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        success(settings);
                    });
                }
            } else {
                if (failure != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        failure([[ZNGError alloc] initWithAPIError:error]);
                    });
                }
            }
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure([[ZNGError alloc] initWithAPIError:error]);
    }];
}

- (void)saveNotificationSettings:(ZNGNotificationSettings * _Nonnull)settings
                       forUserId:(NSString * _Nonnull)userId
                     WithSuccess:(void (^ _Nullable)(void))success
                         failure:(void (^ _Nullable)(ZNGError * _Nullable error))failure
{
    NSString * path = [NSString stringWithFormat:@"notification/%@/preferences", userId];
    
    NSDictionary * parameters = @{
                                  @"desktop": @(settings.desktopMask),
                                  @"mobile": @(settings.mobileMask),
                                  };
    
    [self.session.v2SessionManager PUT:path parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(self->jsonProcessingQueue, ^{
            NSError * error = nil;
            ZNGNotificationSettings * settings = [MTLJSONAdapter modelOfClass:[ZNGNotificationSettings class] fromJSONDictionary:responseObject error:&error];
            
            if (settings != nil) {
                if (success != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        success();
                    });
                }
            } else {
                if (failure != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        failure([[ZNGError alloc] initWithAPIError:error]);
                    });
                }
            }
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure([[ZNGError alloc] initWithAPIError:error]);
    }];
}

@end
