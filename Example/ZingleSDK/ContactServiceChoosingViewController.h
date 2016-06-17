//
//  ContactServiceChoosingViewController.h
//  ZingleSDK
//
//  Created by Jason Neel on 6/17/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactServiceChoosingViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, nullable) IBOutlet UITableView * tableView;

@end
