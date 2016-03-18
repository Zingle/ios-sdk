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

@implementation ZNGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AFNetworkActivityLogger sharedLogger] startLogging];
        
    NSString *token = @"rfarley@zingleme.com";
    NSString *key = @"WfM-uYS-CBV-n6J";
    
    // 1
    [[ZingleSDK sharedSDK] setToken:token andKey:key];
    ZNGInboxViewController *vc = [ZNGInboxViewController withServiceId:@"e545a46e-bfcd-4db2-bfee-8e590fdcb33f"];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController: vc];
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
