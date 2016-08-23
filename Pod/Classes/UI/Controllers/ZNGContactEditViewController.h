//
//  ZNGContactEditViewController.h
//  Pods
//
//  Created by Jason Neel on 8/23/16.
//
//

#import <UIKit/UIKit.h>

@class ZNGContact;

@interface ZNGContactEditViewController : UIViewController <UITableViewDataSource>

@property (nonatomic, strong) IBOutlet NSLayoutConstraint * lockedContactHeightConstraint;

@property (nonatomic, strong) ZNGContact * contact;

@end
