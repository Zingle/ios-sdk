//
//  ZNGDemoViewController.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import "ZNGMessagesViewController.h"
#import "ZNGConversation.h"

#import "ZNGMessages.h"

@class ZNGDemoViewController;

@protocol ZNGDemoViewControllerDelegate <NSObject>

- (void)didDismissZNGDemoViewController:(ZNGDemoViewController *)vc;

@end

@interface ZNGDemoViewController : ZNGMessagesViewController <UIActionSheetDelegate, ZNGMessagesComposerTextViewPasteDelegate, ZNGConversationDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) id<ZNGDemoViewControllerDelegate> delegateModal;

@property (nonatomic, retain) ZNGConversation *conversation;

+ (ZNGDemoViewController *)withConversation:(ZNGConversation *)conversation;

- (void)detailsPressed:(UIBarButtonItem *)sender;

- (void)closePressed:(UIBarButtonItem *)sender;

@end
