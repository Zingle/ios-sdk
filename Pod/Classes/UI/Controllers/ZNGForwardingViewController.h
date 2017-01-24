//
//  ZNGForwardingViewController.h
//  Pods
//
//  Created by Jason Neel on 12/1/16.
//
//

#import <UIKit/UIKit.h>
#import "JSQMessagesViewController/JSQMessagesInputToolbar.h"
#import "ZNGConversationServiceToContact.h"

@class ZNGContact;
@class ZNGMessage;
@class ZNGForwardingInputToolbar;
@class ZNGService;

@interface ZNGForwardingViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate, JSQMessagesInputToolbarDelegate>

@property (nonatomic, strong) ZNGMessage * message;
@property (nonatomic, strong) ZNGConversationServiceToContact * conversation;
@property (nonatomic, strong) ZNGContact * contact;
@property (nonatomic, strong) NSArray<ZNGService *> * availableServices;
@property (nonatomic, strong) ZNGService * activeService;
@property (nonatomic, strong) ZNGService * forwardTargetService;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint * toolbarHeightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint * toolbarBottomSpaceConstraint;
@property (nonatomic, strong) IBOutlet ZNGForwardingInputToolbar * inputToolbar;
@property (nonatomic, strong) IBOutlet UIView * hotsosInputView;
@property (nonatomic, strong) IBOutlet UITextField * roomNumberTextField;
@property (nonatomic, strong) IBOutlet UIButton * selectRecipientTypeButton;
@property (nonatomic, strong) IBOutlet UITextField * textField;
@property (nonatomic, strong) IBOutlet UITextField * hotsosIssueTextField;
@property (nonatomic, strong) IBOutlet UIButton * issueSearchButton;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView * issueSearchActivityIndicator;

- (IBAction) pressedCancel:(id)sender;
- (IBAction) selectRecipientType:(id)sender;
- (IBAction) pressedHotsosIssueSearch:(id)sender;

@end
