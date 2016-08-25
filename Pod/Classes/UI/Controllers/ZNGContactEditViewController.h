//
//  ZNGContactEditViewController.h
//  Pods
//
//  Created by Jason Neel on 8/23/16.
//
//

#import <UIKit/UIKit.h>

@class ZNGContact;
@class ZNGService;

@interface ZNGContactEditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView * tableView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint * lockedContactHeightConstraint;
@property (nonatomic, strong) IBOutlet UINavigationItem * navItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem * cancelButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem * saveButton;

@property (nonatomic, strong) ZNGService * service;
@property (nonatomic, copy) ZNGContact * contact;

- (IBAction)pressedCancel:(id)sender;
- (IBAction)pressedSave:(id)sender;

@end
