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


@interface ZNGAssignmentViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, nullable) ZingleAccountSession * session;
@property (nonatomic, strong, nullable) ZNGContact * contact;

@property (nonatomic, weak, nullable) NSObject <ZNGAssignmentDelegate> * delegate;

@end
