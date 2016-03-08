//
//  UIDevice+ZNGMessages.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <UIKit/UIKit.h>

@interface UIDevice (ZNGMessages)

/**
 *  @return Whether or not the current device is running a version of iOS before 8.0.
 */
+ (BOOL)zng_isCurrentDeviceBeforeiOS8;

@end
