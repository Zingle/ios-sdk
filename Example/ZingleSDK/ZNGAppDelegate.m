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
#import "ZNGConversationViewController.h"

@interface ZNGAppDelegate () <ZNGContactServicesViewControllerDelegate>

@property (nonatomic, strong) UIView *notificationBannerView;

@end

@implementation ZNGAppDelegate

static NSString *kZNGServiceId = @"22111111-1111-1111-1111-111111111111";

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
    
    ZNGInboxViewController *vc = [ZNGInboxViewController withServiceId:kZNGServiceId];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController: vc];
    [self.window makeKeyAndVisible];
    
    // Check if application was launched due to a push notification.
    NSDictionary *notificationData = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notificationData) {
        NSString *contactId = [notificationData objectForKey:@"feedId"];
        
        ZNGConversationViewController *cvc = [[ZingleSDK sharedSDK] conversationViewControllerToContactId:contactId serviceId:kZNGServiceId senderName:@"Me" receiverName:@""];
        
        [vc.navigationController pushViewController:cvc animated:NO];

    }
    
    // TODO: Find a way to nicely demonstrate both InboxVC and the ContactServicesVC.
    //ZNGInboxViewController *vc = [ZNGInboxViewController withServiceId:@"22111111-1111-1111-1111-111111111111"];
    
    //ZNGContactServicesViewController *vc = [ZNGContactServicesViewController withServiceId:@"22111111-1111-1111-1111-111111111111" channelTypeId:@"0a293ea3-4721-433e-a031-610ebcf43255" channelValue:@"+18585557777"];
    //vc.delegate = self;
    
    
    
    

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
    NSString *deviceId = [[[deviceToken.description stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [ZNGNotificationsClient unregisterForNotificationsWithDeviceId:deviceId success:^(ZNGStatus *status) {
        
        [ZNGNotificationsClient registerForNotificationsWithDeviceId:deviceId withServiceIds:@[kZNGServiceId] success:^(ZNGStatus *status) {
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
    // Extract the notification payload.
    
    if (!userInfo) {
        return;
    }
    
    NSString *contactId = [userInfo objectForKey:@"feedId"];
    if (!contactId) {
        return;
    }
    
    NSDictionary *aps = [userInfo objectForKey:@"aps"];
    if (!aps) {
        return;
    }
    
    NSDictionary *alert = [aps objectForKey:@"alert"];
    if (!alert) {
        return;
    }
    
    NSString *body = [alert objectForKey:@"body"];
    if (!body) {
        return;
    }
    
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@" \n"];
    NSString *message = [body stringByTrimmingCharactersInSet:characterSet];
    
    [self application:application handlePushNotificationWithContactId:contactId serviceId:kZNGServiceId message:message];
    
}

// MARK: - Push Notification Helpers

- (void)application:(UIApplication *)application handlePushNotificationWithContactId:(NSString *)contactId serviceId:(NSString *)serviceId message:(NSString *)message
{
    UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
    UIViewController *visibleViewController = navController.visibleViewController;
    
    UIApplicationState state = [application applicationState];
    
    if (state == UIApplicationStateInactive || state == UIApplicationStateBackground) {
        
        if ([visibleViewController isKindOfClass:[ZNGInboxViewController class]]) {
            
            // The InboxViewController is currently visible, so push the ConversationViewController.
            
            ZNGConversationViewController *cvc = [[ZingleSDK sharedSDK] conversationViewControllerToContactId:contactId serviceId:serviceId senderName:@"Me" receiverName:@""];
            [visibleViewController.navigationController pushViewController:cvc animated:NO];
            
        } else if ([visibleViewController isKindOfClass:[ZNGConversationViewController class]]) {
            
            // The ConversationViewController is currently visible.
            
            ZNGConversationViewController *cvc = (ZNGConversationViewController *)visibleViewController;
            
            if ([cvc.contact.contactId isEqualToString:contactId] && [cvc.service.serviceId isEqualToString:serviceId]) {
                
                // Received message from the current contact, so refresh.
                [cvc refreshConversation];
                
            } else {
                
                // Received message from another contact, so replace the existing ConversationViewController with a new one.
                
                UINavigationController *topNavController = visibleViewController.navigationController;
                
                // Remove the existing Conversation View Controller from the view hieararchy.
                [topNavController popViewControllerAnimated:NO];
                
                // Create a new Conversation View Controller and display it.
                ZNGConversationViewController *newCVC = [[ZingleSDK sharedSDK] conversationViewControllerToContactId:contactId serviceId:serviceId senderName:@"Me" receiverName:@""];
                [topNavController pushViewController:newCVC animated:NO];
            }
            
        } else {
            
            // Some other view controller is currently displayed, so display a banner at the top of the screen.
            [self showNotificationBannerForContactId:contactId serviceId:serviceId message:message];
            
        }
    
    } else {
        
        // Application is in UIApplicationStateActive (running in foreground).
        
        if ([visibleViewController isKindOfClass:[ZNGInboxViewController class]]) {
            
            // The InboxViewController is currently visible, so refresh it.
            ZNGInboxViewController *inboxViewController = (ZNGInboxViewController *)visibleViewController;
            [inboxViewController refresh];
            
        } else if ([visibleViewController isKindOfClass:[ZNGConversationViewController class]]) {
            
            // The ConversationViewController is currently visible.
            
            ZNGConversationViewController *cvc = (ZNGConversationViewController *)visibleViewController;
            
            if ([cvc.contact.contactId isEqualToString:contactId] && [cvc.service.serviceId isEqualToString:serviceId]) {
                
                // Received message from the current contact, so refresh.
                [cvc refreshConversation];
                
            } else {
                
                // Received message from another contact, so display a banner at the top of the screen.
                [self showNotificationBannerForContactId:contactId serviceId:serviceId message:message];
            }
            
        } else {
            
            // Some other view controller is currently displayed, so display a banner at the top of the screen.
            [self showNotificationBannerForContactId:contactId serviceId:serviceId message:message];
            
        }
        
    }
    
}

- (void)showNotificationBannerForContactId:(NSString *)contactId serviceId:(NSString *)serviceId message:(NSString *)message
{
    [ZNGContactClient contactWithId:contactId withServiceId:serviceId success:^(ZNGContact *contact, ZNGStatus *status) {
        
        if (self.notificationBannerView) {
            [self.notificationBannerView removeFromSuperview];
            self.notificationBannerView = nil;
        }
        
        self.notificationBannerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, -70.0, self.window.frame.size.width, 80.0)];
        [self.notificationBannerView setBackgroundColor:[UIColor blackColor]];
        [self.notificationBannerView setAlpha:0.90];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, self.window.frame.size.width - 30.0 , 30.0)];
        label.font = [UIFont systemFontOfSize:14.0];
        label.text = [NSString stringWithFormat:@"%@: %@", [contact fullName], message];
        label.textColor = [UIColor whiteColor];
        label.numberOfLines = 1;
        
        [self.notificationBannerView addSubview:label];
        
        [self.window addSubview:self.notificationBannerView];
        
        // Dismiss if touched.
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissNotificationBannerView)];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        tapGestureRecognizer.numberOfTouchesRequired = 1;
        
        [self.notificationBannerView addGestureRecognizer:tapGestureRecognizer];
        
        [UIView animateWithDuration:1.0 delay:.1 usingSpringWithDamping:0.5 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseIn animations:^{
            
            [self.notificationBannerView setFrame:CGRectMake(0.0, 0.0, self.window.frame.size.width, 60.0)];
            
        } completion:^(BOOL finished) {
            
        }];
        
        
        // Dismiss after 5 seconds.
        [self performSelector:@selector(dismissNotificationBannerView) withObject:nil afterDelay:5.0];
        
    } failure:^(ZNGError *error) {
        NSLog(@"error = %@", error.localizedDescription);
    }];
    
}

- (void)dismissNotificationBannerView
{
    [UIView animateWithDuration:1.0 delay:.1 usingSpringWithDamping:0.5 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        [self.notificationBannerView setFrame:CGRectMake(0.0, -70.0, self.window.frame.size.width, 60.0)];
        
    } completion:^(BOOL finished) {
        
    }];
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
