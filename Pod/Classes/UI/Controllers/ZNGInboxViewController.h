//
//  ZNGInboxViewController.h
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGConversationViewController.h"
@class ZNGService;
@class ZNGContact;
@class ZNGInboxDataSet;
@class ZingleAccountSession;

@interface ZNGInboxViewController : UIViewController

+ (nonnull instancetype)inboxViewController;

+ (nonnull instancetype) withSession:(nonnull ZingleAccountSession *)session;

- (void)refresh;

- (void)refresh:(nullable UIRefreshControl *)refreshControl;

@property (strong, nonatomic, nonnull) ZingleAccountSession * session;

@property (strong, nonatomic, nullable) NSIndexPath *selectedIndexPath;
@property (weak, nonatomic, nullable) IBOutlet UITableView *tableView;

@property (nonatomic, strong, nullable) ZNGInboxDataSet * data;

@end
