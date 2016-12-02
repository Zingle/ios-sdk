//
//  ZNGForwardingViewController.h
//  Pods
//
//  Created by Jason Neel on 12/1/16.
//
//

#import <UIKit/UIKit.h>

@class ZNGMessage;

@interface ZNGForwardingViewController : UIViewController

@property (nonatomic, strong) ZNGMessage * message;

- (IBAction) pressedCancel:(id)sender;

@end
