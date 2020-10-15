//
//  ZNGAssignmentViewController.h
//  ZingleSDK
//
//  Created by Jason Neel on 1/11/18.
//

#import <UIKit/UIKit.h>

@class ZingleAccountSession;
@class ZNGAssignmentViewController;
@class ZNGContact;
@class ZNGTeam;
@class ZNGUser;


@protocol ZNGAssignmentDelegate

@optional
- (void) assignmentViewWasCanceled:(ZNGAssignmentViewController * _Nonnull)assignmentView;

@required
- (void) userChoseToUnassignContact:(ZNGContact * _Nonnull)contact;
- (void) userChoseToAssignContact:(ZNGContact * _Nonnull)contact toTeam:(ZNGTeam * _Nonnull)team;
- (void) userChoseToAssignContact:(ZNGContact * _Nonnull)contact toUser:(ZNGUser * _Nonnull)user;

@end


@interface ZNGAssignmentViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating>

@property (nonatomic, strong, nullable) ZingleAccountSession * session;
@property (nonatomic, strong, nullable) ZNGContact * contact;

/**
 *  Optionally hide the contact name when the app is entering the background.
 *  This will prevent contact name from appearing in the app switcher.
 *
 *  Defaults to NO.
 */
@property (nonatomic, assign) BOOL hideContactDataInBackground;

@property (nonatomic, weak, nullable) IBOutlet UITableView * tableView;

@property (nonatomic, weak, nullable) NSObject <ZNGAssignmentDelegate> * delegate;

@end
