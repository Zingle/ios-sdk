//
//  ZNGAppDelegate.m
//  ZingleSDK
//
//  Created by Ryan Farley on 01/31/2016.
//  Copyright (c) 2016 Ryan Farley. All rights reserved.
//

#import "ZNGAppDelegate.h"
#import <ZingleSDK/ZingleSDK.h>
#import <ZingleSDK/ZingleSession.h>

@import SBObjectiveCWrapper;

@implementation ZNGAppDelegate
{
    ZingleContactSession * session;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    
    return YES;
}

// MARK: - Push Notifications

- (void)registerUserNotificationsForApplication:(UIApplication *)application
{
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    
    if (notificationSettings.types != UIUserNotificationTypeNone) {
        [application registerForRemoteNotifications];
    }
    
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)theDeviceToken
{
    [ZingleSession setPushNotificationDeviceToken:theDeviceToken];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Failed to get token, error: %@", error);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    application.applicationIconBadgeNumber = 0;
}

@end
