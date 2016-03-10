//
//  main.m
//  ZingleSDK
//
//  Created by Ryan Farley on 01/31/2016.
//  Copyright (c) 2016 Ryan Farley. All rights reserved.
//

@import UIKit;
#import "ZNGAppDelegate.h"
#import "ZNGTestingAppDelegate.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        BOOL isTesting = NSClassFromString(@"XCTestCase") != Nil;
        Class appDelegateClass = isTesting ? [ZNGTestingAppDelegate class] : [ZNGAppDelegate class];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(appDelegateClass));
    }
}