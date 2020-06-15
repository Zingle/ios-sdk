//
//  ZNGMentionSelectionController.h
//  ZingleSDK
//
//  Created by Jason Neel on 6/4/20.
//
//  Manages a UITableView that is provided on init, keeping it hidden as long as the `mentionSearchText`
//   is empty.
//
//

#import <Foundation/Foundation.h>

@class ZNGMentionSelectionController;
@class ZingleAccountSession;
@class ZNGTeam;
@class ZNGUser;

NS_ASSUME_NONNULL_BEGIN

@protocol ZNGMentionSelectionDelegate

- (void) mentionSelectionController:(ZNGMentionSelectionController *)selectionController didSelectUser:(ZNGUser *)user;
- (void) mentionSelectionController:(ZNGMentionSelectionController *)selectionController didSelectTeam:(ZNGTeam *)team;

@end

@interface ZNGMentionSelectionController : NSObject <UITableViewDataSource, UITableViewDelegate>

- (id) initWithSelectionTable:(UITableView *)tableView session:(ZingleAccountSession *)session delegate:(__weak id <ZNGMentionSelectionDelegate>)delegate;

/**
 * The text to search.  Setting this to nil hides the table.  An empty string returns all matches.
 */
@property (nonatomic, strong, nullable) NSString * mentionSearchText;

@property (nonatomic, strong, nonnull) UITableView * tableView;
@property (nonatomic, strong, nonnull) ZingleAccountSession * session;
@property (nonatomic, weak, nullable) id<ZNGMentionSelectionDelegate> delegate;

@property (nonatomic, strong, nullable) UIFont * headerFont; // defaults to Lato
@property (nonatomic, strong, nullable) UIColor * headerTextColor; // defaults to zingle blue
@property (nonatomic, strong, nullable) UIColor * headerBackgroundColor; // defaults to system background (or white if unsupported)

@end

NS_ASSUME_NONNULL_END
