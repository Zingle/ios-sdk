//
//  ZNGContactEventsViewController.h
//  ZingleSDK
//
//  Created by Jason Neel on 7/12/18.
//

#import <UIKit/UIKit.h>

@class ZNGConversationServiceToContact;

@interface ZNGContactEventsViewController : UIViewController

/**
 *  The conversation whose events we will show.
 *  A cnversation is used instead of `ZNGContact` to make proper formatting of phone number
 *   values easier when a contact does not have a name.
 */
@property (nonatomic, strong, nullable) ZNGConversationServiceToContact * conversation;

@property (nonatomic, strong, nullable) IBOutlet UILabel * titleLabel;
@property (nonatomic, strong, nullable) IBOutlet UITableView * tableView;

- (IBAction) pressedDone:(id)sender;

@end