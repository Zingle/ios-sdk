//
//  ZNGAppDelegate.m
//  ZingleSDK
//
//  Created by Ryan Farley on 01/31/2016.
//  Copyright (c) 2016 Ryan Farley. All rights reserved.
//

#import "ZNGAppDelegate.h"
#import "AFNetworkActivityLogger.h"
#import <ZingleSDK/ZingleSDK.h>
#import "ZNGContactClient.h"
#import "ZNGConversationViewController.h"

@implementation ZNGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    self.window.rootViewController = [[UIViewController alloc] init];
    [self.window makeKeyAndVisible];
    
    [self loadConversation];
    
    return YES;
}

- (void)loadConversation
{
    NSString *token = @"viacheslav.marusyk@cyberhull.com";
    NSString *key = @"123qweasd";
    NSString *contactChannelValue = @"viacheslav.marusyk";
    NSString *contactId = @"b248a5d0-8f01-49eb-bda0-8cf2d13f4700";
    NSString *serviceId = @"e84bec95-b788-45ea-9d64-01db3d8742ac";
    
    // 1
    [[ZingleSDK sharedSDK] setToken:token andKey:key];
    
    // 2
    [[ZingleSDK sharedSDK] addConversationWithServiceId:serviceId contactId:contactId contactChannelValue:contactChannelValue success:^(ZNGConversation *conversation) {
        
        // 3
        ZNGConversationViewController *conversationViewController = [[ZingleSDK sharedSDK] conversationViewControllerForConversation:conversation];
        [self.window.rootViewController presentViewController:conversationViewController animated:YES completion:nil];
        
    } failure:^(ZNGError *error) {
        //
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
