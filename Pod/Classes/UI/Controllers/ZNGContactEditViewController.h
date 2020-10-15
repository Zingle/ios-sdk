//
//  ZNGContactEditViewController.h
//  Pods
//
//  Created by Jason Neel on 8/23/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGAssignmentViewController.h"
#import "ZNGLabelSelectViewController.h"
#import "ZNGContactPhoneNumberTableViewCell.h"

@class ZNGConversationServiceToContact;
@class ZNGGradientLoadingView;
@class ZNGContact;
@class ZNGContactClient;
@class ZNGService;

@protocol ZNGContactEditDelegate <NSObject>

- (void) contactWasCreated:(ZNGContact *)contact;

@end

@interface ZNGContactEditViewController : UIViewController <UITableViewDataSource,
                                                            UITableViewDelegate,
                                                            ZNGLabelSelectionDelegate,
                                                            ZNGContactPhoneNumberTableCellDelegate,
                                                            ZNGAssignmentDelegate,
                                                            UIViewControllerTransitioningDelegate>
@property (nonatomic, strong) IBOutlet UITableView * tableView;
@property (nonatomic, strong) IBOutlet ZNGGradientLoadingView * loadingGradient;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint * lockedContactHeightConstraint;
@property (nonatomic, strong) IBOutlet UIButton * saveButton;
@property (nonatomic, strong) IBOutlet UIButton * cancelButton;
@property (nonatomic, strong) IBOutlet UILabel * titleLabel;
@property (nonatomic, strong) IBOutlet UIView * titleContainer;

/**
 *  Reference to the name label in the contact assignment table cell, if available and visible.
 */
@property (nonatomic, readonly) __weak UILabel * assignmentLabel;

@property (nonatomic, strong) ZNGConversationServiceToContact * conversation;
@property (nonatomic, strong) ZNGContactClient * contactClient;
@property (nonatomic, strong) ZNGService * service;
@property (nonatomic, copy) ZNGContact * contact;

@property (nonatomic, assign) BOOL useDefaultTransition;

/**
 *  Optionally hide all contact and messaging data when the app is entering the background.
 *  This will prevent contact data from appearing in the app switcher.
 *
 *  Defaults to NO.
 */
@property (nonatomic, assign) BOOL hideContactDataInBackground;

@property (nonatomic, weak) id <ZNGContactEditDelegate> delegate;

- (IBAction)pressedCancel:(id)sender;
- (IBAction)pressedSave:(id)sender;

@end
