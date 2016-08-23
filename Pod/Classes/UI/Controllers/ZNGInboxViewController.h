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
@class ZNGInboxViewController;

@protocol ZNGInboxDelegate <NSObject>

@optional

/**
 *  Optional delegate method that can be used to prevent the inbox view from displaying its own conversation view.
 *  The user may return NO from this method and display his own conversation UI.
 */
- (BOOL) inbox:(nonnull ZNGInboxViewController *)inbox shouldPresentConversation:(nonnull ZNGConversation *)conversation;

@end

@interface ZNGInboxViewController : UIViewController

+ (nonnull instancetype)inboxViewController;

+ (nonnull instancetype) withSession:(nonnull ZingleAccountSession *)session;

- (void)refresh;

- (void)refresh:(nullable UIRefreshControl *)refreshControl;

@property (nonatomic, weak, nullable) id <ZNGInboxDelegate> delegate;

@property (strong, nonatomic, nonnull) ZingleAccountSession * session;

@property (strong, nonatomic, nullable) NSIndexPath *selectedIndexPath;
@property (weak, nonatomic, nullable) IBOutlet UITableView *tableView;

@property (nonatomic, strong, nullable) ZNGInboxDataSet * data;

@end
