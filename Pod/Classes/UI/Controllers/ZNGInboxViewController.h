//
//  ZNGInboxViewController.h
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGConversationViewController.h"
#import "MGSwipeTableCell/MGSwipeTableCell.h"
@class ZNGService;
@class ZNGContact;
@class ZNGInboxDataSet;
@class ZingleAccountSession;
@class ZNGInboxViewController;
@class ZNGInboxDataSet;

@protocol ZNGInboxDelegate <NSObject>

@optional

/**
 *  Optional delegate method that can be used to prevent the inbox view from displaying its own conversation view.
 *  The user may return NO from this method and display his own conversation UI.
 */
- (BOOL) inbox:(nonnull ZNGInboxViewController *)inbox shouldPresentConversation:(nonnull ZNGConversation *)conversation;

@end

@interface ZNGInboxViewController : UIViewController <MGSwipeTableCellDelegate, UITableViewDataSource, UITableViewDelegate>

+ (nonnull instancetype)inboxViewController;

+ (nonnull instancetype) withSession:(nonnull ZingleAccountSession *)session;

/**
 *  Returns a refresh control that is styled appropriately and has the correct action setup.
 */
- (nonnull UIRefreshControl *) configuredRefreshControl;

- (void)refresh;

- (void)refresh:(nullable UIRefreshControl *)refreshControl;

/**
 *  The data set that will be used if the view appears without any current data.  Defaults to a new ZNGInboxDataSet.
 */
- (ZNGInboxDataSet * _Nonnull) initialDataSet;

@property (nonatomic, weak, nullable) id <ZNGInboxDelegate> delegate;

@property (strong, nonatomic, nonnull) ZingleAccountSession * session;

@property (weak, nonatomic, nullable) IBOutlet UITableView *tableView;

@property (nonatomic, strong, nullable) ZNGInboxDataSet * data;

/**
 *  Read/write property that indicates the visually selected contact.
 *
 *  Setting this to a non-nil ZNGContact that is in our current data will cause that row to be highlighted and scrolled on screen (if necessary.)
 *
 *  Setting this to nil or to a contact that is not present in our data will deselect any current selection
 */
@property (nonatomic, strong, nullable) ZNGContact * selectedContact;

@end
