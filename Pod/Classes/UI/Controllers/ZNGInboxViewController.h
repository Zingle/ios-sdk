//
//  ZNGInboxViewController.h
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import <UIKit/UIKit.h>

@interface ZNGInboxViewController : UIViewController

+ (instancetype)inboxViewController;

+ (instancetype)withServiceId:(NSString *)serviceId;

@end
