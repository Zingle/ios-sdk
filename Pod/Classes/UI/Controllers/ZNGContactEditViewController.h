//
//  ZNGContactEditViewController.h
//  Pods
//
//  Created by Jason Neel on 8/23/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGLabelSelectViewController.h"

@class GradientLoadingView;
@class ZNGContact;
@class ZNGContactClient;
@class ZNGService;

@interface ZNGContactEditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, ZNGLabelSelectionDelegate>

@property (nonatomic, strong) IBOutlet UITableView * tableView;
@property (nonatomic, strong) IBOutlet GradientLoadingView * loadingGradient;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint * lockedContactHeightConstraint;
@property (nonatomic, strong) IBOutlet UINavigationItem * navItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem * cancelButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem * saveButton;

@property (nonatomic, strong) ZNGContactClient * contactClient;
@property (nonatomic, strong) ZNGService * service;
@property (nonatomic, copy) ZNGContact * contact;

- (IBAction)pressedCancel:(id)sender;
- (IBAction)pressedSave:(id)sender;

@end
