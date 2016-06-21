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
#import "ZNGServiceClient.h"
#import "ZNGConversationViewController.h"
#import "ZingleAccountSession.h"
#import "ZingleContactSession.h"

@interface ZNGAppDelegate () <ZNGContactServicesViewControllerDelegate>

@property (nonatomic, strong) UIView *notificationBannerView;
@property (nonatomic, assign) BOOL userAccountEnabled;

@end

@implementation ZNGAppDelegate
{
    ZingleSession * session;
}

static NSString *kZNGToken = @"[YOUR ZINGLE TOKEN]";
static NSString *kZNGKey = @"[YOUR ZINGLE KEY]";

static NSString *kZNGServiceId = @"22111111-1111-1111-1111-111111111111";

// User-Defined Channel if using Contact User Authorization
static NSString *kZNGChannelTypeId = @"7176e36e-87d2-4161-ae2b-6848fbf3de11";
static NSString *kZNGChannelValue = @"MyChatChannel1";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /******************************************************************************************
    * Uncomment the appropriate line below depending on which type of Zingle Account you have.
    ******************************************************************************************/
    //[self accountApplication:application didFinishLaunchingWithOptions:launchOptions];
    [self contactApplication:application didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
}

- (void)accountApplication:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.userAccountEnabled = YES;
    
    [self registerUserNotificationsForApplication:application];
    
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [AFNetworkActivityLogger sharedLogger].level = AFLoggerLevelDebug;
    
    // We will just pick the first available of each category if multiples are available
    session = [ZingleSDK accountSessionWithToken:kZNGToken key:kZNGKey accountChooser:^ZNGAccount * _Nullable(NSArray<ZNGAccount *> * _Nonnull availableAccounts) {
        return [availableAccounts firstObject];
    } serviceChooser:^ZNGService * _Nullable(NSArray<ZNGService *> * _Nonnull availableServices) {
        return [availableServices firstObject];
    }];
    
    ZNGInboxViewController *vc = [ZNGInboxViewController withSession:(ZingleAccountSession *)session];
    
     self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
     self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController: vc];
     [self.window makeKeyAndVisible];
     
     // Check if application was launched due to a push notification.
     NSDictionary *notificationData = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
     if (notificationData) {
     NSString *contactId = [notificationData objectForKey:@"feedId"];
         [self navigateToConversationViewControllerWithContactId:contactId serviceId:kZNGServiceId fromViewController:vc animated:NO];
     }
}

- (void)contactApplication:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.userAccountEnabled = NO;
    
    [self registerUserNotificationsForApplication:application];
    
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [AFNetworkActivityLogger sharedLogger].level = AFLoggerLevelDebug;
    
    // We are not actually picking a contact service.  We are using this block as our trigger to know that a selection is now available.
    ZNGContactServicesViewController * vc = [ZNGContactServicesViewController contactServicesViewController];
    vc.delegate = self;
    
    // We will just pick the first available of each category if multiples are available
    session = [ZingleSDK contactSessionWithToken:kZNGToken key:kZNGKey channelTypeId:kZNGChannelTypeId channelValue:kZNGChannelValue contactServiceChooser:^ZNGContactService * _Nullable(NSArray<ZNGContactService *> * _Nonnull availableContactServices) {
        vc.availableContactServices = availableContactServices;
        return nil;
    }];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController: vc];
    [self.window makeKeyAndVisible];
    
    // Check if application was launched due to a push notification.
    NSDictionary *notificationData = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notificationData) {
        NSString *contactId = [notificationData objectForKey:@"feedId"];
        
        [self navigateToConversationViewControllerWithContactId:contactId serviceId:kZNGServiceId fromViewController:vc animated:NO];
    }
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

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    session.pushNotificationDeviceToken = [[NSString alloc] initWithData:deviceToken encoding:NSUTF8StringEncoding];
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

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    application.applicationIconBadgeNumber = 0;
}

// MARK: - Push Notification Helpers

- (void)navigateToConversationViewControllerWithContactId:(NSString *)contactId serviceId:(NSString *)serviceId fromViewController:(UIViewController *)sourceViewController animated:(BOOL)animated
{
    [session.serviceClient serviceWithId:serviceId success:^(ZNGService *service, ZNGStatus *status) {
        
        [session.contactClient contactWithId:contactId success:^(ZNGContact *contact, ZNGStatus *status) {
            
            ZNGConversationViewController *cvc = nil;
            if (self.userAccountEnabled) {
                ZingleAccountSession * accountSession = (ZingleAccountSession *)session;
                ZNGConversation * conversation = [accountSession conversationWithContact:contact];
                cvc = [accountSession conversationViewControllerForConversation:conversation];
            } else {
                ZingleContactSession * contactSession = (ZingleContactSession *)session;
                cvc = [contactSession conversationViewController];
            }
            
            if (!sourceViewController) {
                UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
                [navController popToRootViewControllerAnimated:NO];
                [navController pushViewController:cvc animated:animated];
            } else if ([sourceViewController isKindOfClass:[UINavigationController class]]) {
                UINavigationController *navController = (UINavigationController *)sourceViewController;
                [navController pushViewController:cvc animated:animated];
            } else {
                [sourceViewController.navigationController pushViewController:cvc animated:animated];
            }
            
        } failure:^(ZNGError *error) {
            NSLog(@"error = %@", error.localizedDescription);
        }];
        
    } failure:^(ZNGError *error) {
        NSLog(@"error = %@", error.localizedDescription);
    }];
}

- (void)application:(UIApplication *)application handlePushNotificationWithContactId:(NSString *)contactId serviceId:(NSString *)serviceId message:(NSString *)message
{
    UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
    UIViewController *visibleViewController = navController.visibleViewController;
    
    UIApplicationState state = [application applicationState];
    
    
    if (state == UIApplicationStateInactive || state == UIApplicationStateBackground) {
        
        if ([visibleViewController isKindOfClass:[ZNGInboxViewController class]]) {
            
            [self navigateToConversationViewControllerWithContactId:contactId serviceId:serviceId fromViewController:visibleViewController animated:NO];
        
        } else if ([visibleViewController isKindOfClass:[ZNGConversationViewController class]]) {
            
            // The ConversationViewController is currently visible.
            
            ZNGConversationViewController *cvc = (ZNGConversationViewController *)visibleViewController;
            
            if ([cvc.conversation.contactId isEqualToString:contactId] && [cvc.conversation.serviceId isEqualToString:serviceId]) {
                
                // Received message from the current contact, so refresh.
                [cvc refreshConversation];
                
            } else {
                
                // Received message from another contact, so replace the existing ConversationViewController with a new one.
                
                [self navigateToConversationViewControllerWithContactId:contactId serviceId:serviceId fromViewController:nil animated:NO];
                
            }
            
        } else {
            
            // Some other view controller is currently displayed, so display a banner at the top of the screen.
            [self showNotificationBannerForContactId:contactId message:message];
            
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
            
            if ([cvc.conversation.contactId isEqualToString:contactId] && [cvc.conversation.serviceId isEqualToString:serviceId]) {
                
                // Received message from the current contact, so refresh.
                [cvc refreshConversation];
                
            } else {
                
                // Received message from another contact, so display a banner at the top of the screen.
                [self showNotificationBannerForContactId:contactId message:message];
            }
            
        } else {
            
            // Some other view controller is currently displayed, so display a banner at the top of the screen.
            [self showNotificationBannerForContactId:contactId message:message];
            
        }
        
    }
    
}

- (void)showNotificationBannerForContactId:(NSString *)contactId message:(NSString *)message
{
    
    [session.contactClient contactWithId:contactId success:^(ZNGContact *contact, ZNGStatus *status) {
        
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

- (void)contactServicesViewControllerDidSelectContactService:(ZNGContactService *)contactService
{
    ZingleContactSession * contactSession = (ZingleContactSession *)session;
    contactSession.contactService = contactService;
}

@end
