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
@class ZNGService;

@interface ZNGForwardingViewController : UIViewController <UITextViewDelegate>

@property (nonatomic, strong) ZNGMessage * message;
@property (nonatomic, strong) NSArray<ZNGService *> * availableServices;
@property (nonatomic, strong) ZNGService * selectedService;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint * toolbarHeightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint * toolbarBottomSpaceConstraint;
@property (nonatomic, strong) IBOutlet ZNGForwardingInputToolbar * inputToolbar;

@property (nonatomic, strong) IBOutlet UIButton * selectRecipientTypeButton;
@property (nonatomic, strong) IBOutlet UITextField * textField;

- (IBAction) pressedCancel:(id)sender;
- (IBAction) selectRecipientType:(id)sender;

@end
