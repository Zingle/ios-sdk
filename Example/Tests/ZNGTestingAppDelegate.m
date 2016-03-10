//
//  ZNGTestingAppDelegate.m
//  ZingleSDK
//
//  Created by Ryan Farley on 3/10/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import "ZNGTestingAppDelegate.h"
#import "AFNetworkActivityLogger.h"

@implementation ZNGTestingAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
    
    return YES;
}

@end