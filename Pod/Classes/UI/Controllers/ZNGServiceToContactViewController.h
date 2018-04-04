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

@protocol  ZNGServiceToContactViewDelegate <NSObject>

@optional

/**
 *  Optional delegate method that is called when the user pressed 'Edit Contact.'
 *  If this method is implemented and returns NO, the edit contact screen will not be shown, instead allowing the delegate
 *   to present UI.
 */
- (BOOL) shouldShowEditContactScreenForContact:(nonnull ZNGContact *)contact;

@end


@interface ZNGServiceToContactViewController : ZNGConversationViewController <ZNGAssignmentDelegate>

@property (weak, nonatomic, readonly, nullable) ZNGServiceConversationInputToolbar * inputToolbar;

@property (nonatomic, strong, nullable) ZNGConversationServiceToContact * conversation;

@property (nonatomic, weak, nullable) id <ZNGServiceToContactViewDelegate> delegate;

/**
 *  Setting this flag hides the contact name (potentially only the first line of the title on services with assignment).
 *  Used for animated transitions.
 */
@property (nonatomic, assign) BOOL hideContactName;

@property (nonatomic, strong, nullable) IBOutlet UIView * automationBannerContainerView;
@property (nonatomic, strong, nullable) IBOutlet UIView * automationBanner;
@property (nonatomic, strong, nullable) IBOutlet UILabel * automationLabel;
@property (nonatomic, strong, nullable) IBOutlet NSLayoutConstraint * automationBannerOnScreenConstraint;
@property (nonatomic, strong, nullable) IBOutlet NSLayoutConstraint * automationBannerOffScreenConstraint;
@property (nonatomic, strong, nullable) IBOutlet UIButton * automationCancelButton;
@property (nonatomic, strong, nullable) IBOutlet UILabel * automationRobot;

- (IBAction)pressedCancelAutomation:(nullable id)sender;

// Defaults to YES
@property (nonatomic, assign) BOOL allowForwarding;

@end
