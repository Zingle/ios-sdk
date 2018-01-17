//
//  ZNGContactEditViewController.h
//  Pods
//
//  Created by Jason Neel on 8/23/16.
//
//

#import <UIKit/UIKit.h>
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

@interface ZNGContactEditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ZNGLabelSelectionDelegate, ZNGContactPhoneNumberTableCellDelegate>

@property (nonatomic, strong) IBOutlet UITableView * tableView;
@property (nonatomic, strong) IBOutlet ZNGGradientLoadingView * loadingGradient;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint * lockedContactHeightConstraint;
@property (nonatomic, strong) IBOutlet UIButton * saveButton;
@property (nonatomic, strong) IBOutlet UILabel * titleLabel;

@property (nonatomic, strong) ZNGConversationServiceToContact * conversation;
@property (nonatomic, strong) ZNGContactClient * contactClient;
@property (nonatomic, strong) ZNGService * service;
@property (nonatomic, copy) ZNGContact * contact;

@property (nonatomic, weak) id <ZNGContactEditDelegate> delegate;

- (IBAction)pressedCancel:(id)sender;
- (IBAction)pressedSave:(id)sender;

@end
