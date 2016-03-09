//
//  ZNGConversationViewController.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import "ZNGBaseViewController.h"
#import "ZNGHeaders.h"

@class ZNGConversationViewController;

@protocol ZNGConversationViewControllerDelegate <NSObject>

- (void)didDismissZNGConversationViewController:(ZNGConversationViewController *)vc;

@end

@interface ZNGConversationViewController : ZNGBaseViewController <UIActionSheetDelegate, ZNGComposerTextViewPasteDelegate, ZNGConversationDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate>


+ (ZNGConversationViewController *)withConversation:(ZNGConversation *)conversation;

@property (weak, nonatomic) id<ZNGConversationViewControllerDelegate> delegateModal;

//OPTIONAL UI SETTINGS
@property (nonatomic, strong) UIColor *incomingBubbleColor;
@property (nonatomic, strong) UIColor *outgoingBubbleColor;
@property (nonatomic, strong) UIColor *incomingTextColor;
@property (nonatomic ,strong) UIColor *outgoingTextColor;
@property (nonatomic, strong) UIColor *authorTextColor;
@property (nonatomic, copy) NSString *senderName;
@property (nonatomic, copy) NSString *receiverName;

- (void)closePressed:(UIBarButtonItem *)sender;

@end
