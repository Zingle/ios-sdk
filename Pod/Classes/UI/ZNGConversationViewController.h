//
//  ZNGConversationViewController.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import "ZNGBaseViewController.h"
#import "ZNGConversation.h"

#import "ZNGHeaders.h"

@class ZNGConversationViewController;

@protocol ZNGConversationViewControllerDelegate <NSObject>

- (void)didDismissZNGConversationViewController:(ZNGConversationViewController *)vc;

@end

@interface ZNGConversationViewController : ZNGBaseViewController <UIActionSheetDelegate, ZNGComposerTextViewPasteDelegate, ZNGConversationDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) id<ZNGConversationViewControllerDelegate> delegateModal;

@property (nonatomic, retain) ZNGConversation *conversation;

+ (ZNGConversationViewController *)withConversation:(ZNGConversation *)conversation;

- (void)detailsPressed:(UIBarButtonItem *)sender;

- (void)closePressed:(UIBarButtonItem *)sender;

@end
