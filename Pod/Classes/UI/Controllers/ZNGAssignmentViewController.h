//
//  ZNGAssignmentViewController.h
//  ZingleSDK
//
//  Created by Jason Neel on 1/11/18.
//

#import <UIKit/UIKit.h>

@class ZNGConversationServiceToContact;

@interface ZNGAssignmentViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, nullable) ZNGConversationServiceToContact * conversation;

@end
