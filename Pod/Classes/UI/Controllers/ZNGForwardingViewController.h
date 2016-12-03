//
//  ZNGForwardingViewController.h
//  Pods
//
//  Created by Jason Neel on 12/1/16.
//
//

#import <UIKit/UIKit.h>

@class ZNGMessage;
@class ZNGForwardingInputToolbar;

@interface ZNGForwardingViewController : UIViewController

@property (nonatomic, strong) ZNGMessage * message;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint * toolbarHeightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint * toolbarBottomSpaceConstraint;
@property (nonatomic, strong) IBOutlet ZNGForwardingInputToolbar * inputToolbar;

- (IBAction) pressedCancel:(id)sender;

@end
