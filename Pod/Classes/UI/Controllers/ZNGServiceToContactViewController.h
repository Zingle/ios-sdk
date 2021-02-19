//
//  ZNGServiceToContactViewController.h
//  Pods
//
//  Created by Jason Neel on 7/5/16.
//
//

#import <ZingleSDK/ZNGConversationViewController.h>
#import "ZNGConversationServiceToContact.h"
#import "ZNGAssignmentViewController.h"
#import "ZNGMentionSelectionController.h"

@protocol  ZNGServiceToContactViewDelegate <NSObject>

@optional

/**
 *  Optional delegate method that is called when the user pressed 'Edit Contact.'
 *  If this method is implemented and returns NO, the edit contact screen will not be shown, instead allowing the delegate
 *   to present UI.
 */
- (BOOL) shouldShowEditContactScreenForContact:(nonnull ZNGContact *)contact;

@end


@interface ZNGServiceToContactViewController : ZNGConversationViewController <ZNGAssignmentDelegate, ZNGMentionSelectionDelegate>

@property (weak, nonatomic, readonly, nullable) ZNGServiceConversationInputToolbar * inputToolbar;

@property (nonatomic, strong, nullable) ZNGConversationServiceToContact * conversation;

@property (nonatomic, weak, nullable) id <ZNGServiceToContactViewDelegate> delegate;

/**
 *  Setting this flag hides the contact name (potentially only the first line of the title on services with assignment).
 *  Used for animated transitions.
 */
@property (nonatomic, assign) BOOL hideContactName;

/**
 *  Optionally hide all contact and messaging data when the app is entering the background.
 *  This will prevent contact data from appearing in the app switcher.
 *  This will also propogate to any contact edit, event, and assignment view controllers presented by this conversation view.
 *
 *  Defaults to NO.
 */
@property (nonatomic, assign) BOOL hideContactDataInBackground;

/**
 *  Setting this flag hides the assignment name, e.g. "Jason" in "Assigned to Jason".
 *  Used for animated transitions.
 */
@property (nonatomic, assign) BOOL hideAssignmentName;

@property (nonatomic, strong, nullable) IBOutlet UIView * automationBannerContainerView;
@property (nonatomic, strong, nullable) IBOutlet UIView * automationBanner;
@property (nonatomic, strong, nullable) IBOutlet UILabel * automationLabel;
@property (nonatomic, strong, nullable) IBOutlet NSLayoutConstraint * automationBannerOnScreenConstraint;
@property (nonatomic, strong, nullable) IBOutlet NSLayoutConstraint * automationBannerOffScreenConstraint;
@property (nonatomic, strong, nullable) IBOutlet UIButton * automationCancelButton;
@property (nonatomic, strong, nullable) IBOutlet UILabel * automationRobot;
@property (nonatomic, strong, nullable) IBOutlet UITableView * mentionsSelectionTable;

// A toolbar that only exists to visually cover the gap between the bottom of JSQMessage's toolbar and the bottom of the safe zone
@property (nonatomic, strong, nullable) IBOutlet UIToolbar * lowerFacadeToolbar;

- (IBAction)pressedCancelAutomation:(nullable id)sender;

// Defaults to YES
@property (nonatomic, assign) BOOL allowForwarding;

@end
