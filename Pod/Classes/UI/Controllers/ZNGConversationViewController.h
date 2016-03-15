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

/**
 *  Returns a ZNGConversationViewController.
 *
 *  @param conversation Object containing participants in a conversation and the 
 *  conversation messages. Controller must be created with conversation.
 */
+ (ZNGConversationViewController *)withConversation:(ZNGConversation *)conversation;



/**
 *  If ZNGConversationViewController is presented modally the delegateModel should
 *  should be set to handle dismissing the modal.
 *
 *  @param delegateModal Object conforming to ZNGConversationViewControllerDelegate 
 *  that should handle dismissing the ZNGConversationViewController.
 */
@property (weak, nonatomic) id<ZNGConversationViewControllerDelegate> delegateModal;

/**
 * OPTIONAL UI SETTINGS
 */

/**
 *  Sets the background color of the incoming bubble.
 *
 *  @param incomingBubbleColor Will use default Zingle light gray if not set.
 */
@property (nonatomic, strong) UIColor *incomingBubbleColor;

/**
 *  Sets the background color of the outgoing bubble.
 *
 *  @param outgoingBubbleColor Will use default Zingle blue if not set.
 */
@property (nonatomic, strong) UIColor *outgoingBubbleColor;

/**
 *  Sets the text color of the incoming message text.
 *
 *  @param incomingTextColor Will use default Zingle gray text color if not set.
 */
@property (nonatomic, strong) UIColor *incomingTextColor;

/**
 *  Sets the text color of the outgoing message text.
 *
 *  @param outgoingTextColor Will use default Zingle gray text color if not set.
 */
@property (nonatomic ,strong) UIColor *outgoingTextColor;

/**
 *  Sets the text color of the label on top of the message bubble.
 *
 *  @param authorTextColor Will use [UIColor lightGrayColor] if not set.
 */
@property (nonatomic, strong) UIColor *authorTextColor;

/**
 *  Sets the name of the sender to be displayed above message bubbles.
 *
 *  @param senderName If this is not set the label on top of the sender's message
 *  bubble will be hidden.
 */
@property (nonatomic, copy) NSString *senderName;

/**
 *  Sets the name of the receiver to be displayed above message bubbles.
 *
 *  @param receiverName If this is not set the label on top of the receiver's message
 *  bubble will say "Received".
 */
@property (nonatomic, copy) NSString *receiverName;

@end
