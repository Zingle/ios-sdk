//
//  ZNGAssignmentViewController.h
//  ZingleSDK
//
//  Created by Jason Neel on 1/11/18.
//

#import <UIKit/UIKit.h>

@class ZingleAccountSession;

@interface ZNGAssignmentViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, nullable) ZingleAccountSession * session;

@end
