//
//  ZNGAppDelegate.m
//  ZingleSDK
//
//  Created by Ryan Farley on 01/31/2016.
//  Copyright (c) 2016 Ryan Farley. All rights reserved.
//

#import "ZNGAppDelegate.h"
#import <ZingleSDK/ZingleSDK.h>
#import "ZNGInboxViewController.h"
#import "ZNGContactServicesViewController.h"
#import "AFNetworkActivityLogger.h"
#import "ZNGContactServiceClient.h"
#import "ZNGContactClient.h"
#import "ZNGNotificationsClient.h"

@interface ZNGAppDelegate () <ZNGContactServicesViewControllerDelegate>

@end

@implementation ZNGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [AFNetworkActivityLogger sharedLogger].level = AFLoggerLevelDebug;
    
    NSString *token = @"[YOUR ZINGLE TOKEN]";
    NSString *key = @"[YOUR ZINGLE KEY]";
    
    // 1
    [[ZingleSDK sharedSDK] setToken:token andKey:key forDebugMode:YES];
    
    // 2
    // Register for User Notifications
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    
    // TODO: Find a way to nicely demonstrate both InboxVC and the ContactServicesVC.
    //ZNGInboxViewController *vc = [ZNGInboxViewController withServiceId:@"22111111-1111-1111-1111-111111111111"];
    
    ZNGContactServicesViewController *vc = [ZNGContactServicesViewController withServiceId:@"22111111-1111-1111-1111-111111111111" channelTypeId:@"0a293ea3-4721-433e-a031-610ebcf43255" channelValue:@"+18585557777"];
    vc.delegate = self;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController: vc];
    [self.window makeKeyAndVisible];
    
    return YES;
}

// 3
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    
    if (notificationSettings.types) {
        [application registerForRemoteNotifications];
    }
    
}

// 4
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    // TODO: Load serviceId from NSUserDefaults.
    NSString *serviceId = @"22111111-1111-1111-1111-111111111111";
    
    NSString *deviceId = [[[deviceToken.description stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [ZNGNotificationsClient unregisterForNotificationsWithDeviceId:deviceId success:^(ZNGStatus *status) {
        
        [ZNGNotificationsClient registerForNotificationsWithDeviceId:deviceId withServiceIds:@[serviceId] success:^(ZNGStatus *status) {
            NSLog(@"%@", status);
        } failure:^(ZNGError *error) {
            NSLog(@"error: %@", error);
        }];
        
    } failure:^(ZNGError *error) {
        NSLog(@"error: %@", error);
    }];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"zng_receivePushNotification" object:nil userInfo:userInfo];
}

// MARK: - ZNGContactServicesViewControllerDelegate

- (void)contactServicesViewControllerDidSelectContactService:(ZNGContactService *)contactService {
    
    [[ZingleSDK sharedSDK] checkAuthorizationForContactService:contactService success:^(BOOL isAuthorized) {
        
        if (isAuthorized) {
            
            ZNGInboxViewController *vc = [ZNGInboxViewController withServiceId:contactService.serviceId];
            
            UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
            [navController pushViewController:vc animated:YES];
            
        }
        
    } failure:^(ZNGError *error) {
        NSLog(@"error: %@", error);
    }];
    
    
    
    
    
    
    
    
}

@end
