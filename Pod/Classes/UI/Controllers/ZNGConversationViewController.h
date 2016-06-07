//
//  ZNGConversationViewController.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import "ZNGBaseViewController.h"
#import "ZNGHeaders.h"
#import "ZNGContact.h"

@class ZNGConversationViewController;

@protocol ZNGConversationModalDelegate <NSObject>

@optional
- (void)didDismissZNGConversationViewController:(ZNGConversationViewController *)vc;

@end

@protocol ZNGConversationDetailDelegate <NSObject>

@optional
- (void)didUpdateContact;

@end

@interface ZNGConversationViewController : ZNGBaseViewController <ZNGComposerTextViewPasteDelegate, ZNGConversationDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

/**
 *  Returns a ZNGConversationViewController.
 *
 *  @param conversation Object containing participants in a conversation and the 
 *  conversation messages. Controller must be created with conversation.
 */
+ (ZNGConversationViewController *)toService:(ZNGService *)service
                                     contact:(ZNGContact *)contact
                                  senderName:(NSString *)senderName
                                receiverName:(NSString *)receiverName;

/**
 *  Returns a ZNGConversationViewController.
 *
 *  @param conversation Object containing participants in a conversation and the
 *  conversation messages. Controller must be created with conversation.
 */
+ (ZNGConversationViewController *)toContact:(ZNGContact *)contact
                                     service:(ZNGService *)service
                                  senderName:(NSString *)senderName
                                receiverName:(NSString *)receiverName;

/**
 *  If ZNGConversationViewController is presented modally the modalDelegate should
 *  should be set to handle dismissing the modal.
 *
 *  @param delegateModal Object conforming to ZNGConversationModalDelegate
 *  that should handle dismissing the ZNGConversationViewController.
 */
@property (weak, nonatomic) id<ZNGConversationModalDelegate> modalDelegate;

/**
 *  If ZNGConversationViewController is presented with a master detail view the
 *  detailDelegate should be used to update the master view.
 *
 *  @param detailDelegate Object conforming to ZNGConversationDetailDelegate
 *  that should handle updating the master view.
 */
@property (weak, nonatomic) id<ZNGConversationDetailDelegate> detailDelegate;

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

/**
 *  Sets whether or not the messages should be automatically marked as read.
 *
 *  @param autoMarkAsReadEnabled If YES, then the messages are automatically marked as read.
 *  Default value is NO.
 */
@property (nonatomic, assign, getter=isAutoMarkAsReadEnabled) BOOL autoMarkAsReadEnabled;

// Temporarily exposed during development

@property (nonatomic) BOOL toService;
@property (nonatomic, strong) ZNGService *service;
@property (nonatomic, strong) ZNGContact *contact;
@property (nonatomic, strong) ZNGConversation *conversation;
- (void)refreshViewModels;
- (void)loadConversation;
- (void)setupBarButtonItems;
- (void)refreshContact;
- (void)refreshConversation;
- (void)updateToLastMessage;

@end
