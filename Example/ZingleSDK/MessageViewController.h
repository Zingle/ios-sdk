//
//  MessageViewController.h
//  ZingleSDK
//
//  Created by Jason Neel on 6/20/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZNGContactService;
@class ZingleContactSession;

@interface MessageViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, nullable) ZingleContactSession * session;
@property (nonatomic, strong, nullable) ZNGContactService * contactService;

@property (nonatomic, strong, nullable) IBOutlet UIButton * attachButton;
@property (nonatomic, strong, nullable) IBOutlet UIButton * sendButton;
@property (nonatomic, strong, nullable) IBOutlet UITextField * inputTextField;
@property (nonatomic, strong, nullable) IBOutlet UITableView * tableView;

@end
