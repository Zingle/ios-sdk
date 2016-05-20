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
#import "AFNetworkActivityLogger.h"

#import "ZNGContactClient.h"

@implementation ZNGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [AFNetworkActivityLogger sharedLogger].level = AFLoggerLevelDebug;
    
    NSString *token = @"[YOUR ZINGLE TOKEN]";
    NSString *key = @"[YOUR ZINGLE KEY]";
    
    // 1
    [[ZingleSDK sharedSDK] setToken:token andKey:key forDebugMode:YES];
    ZNGInboxViewController *vc = [ZNGInboxViewController withServiceId:@"[YOUR ZINGLE SERVICE ID]"];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController: vc];
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
