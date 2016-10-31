//
//  ZNGConversationViewController.h
//  Pods
//
//  Created by Jason Neel on 6/20/16.
//
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>
#import "ZNGServiceConversationInputToolbar.h"

@class ZNGConversation;
@class ZNGConversationViewController;
@class ZNGMessage;
@class ZNGEvent;

NS_ASSUME_NONNULL_BEGIN

@interface ZNGConversationViewController : JSQMessagesViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, ZNGServiceConversationInputToolbarDelegate>

@property (nonatomic, strong, nullable) ZNGConversation * conversation;

/**
 *  Returns the input toolbar view object managed by this view controller.
 *  This view controller is the toolbar's delegate.
 */
@property (weak, nonatomic, readonly) ZNGConversationInputToolbar * inputToolbar;

/**
 * OPTIONAL UI SETTINGS
 */

/**
 *  Sets the background color of the incoming bubble.
 *
 *  @param incomingBubbleColor Defaults to Zingle light gray.
 */
@property (nonatomic, strong) UIColor *incomingBubbleColor;

/**
 *  Sets the background color of the outgoing bubble.
 *
 *  @param outgoingBubbleColor Defaults to default Zingle blue
 */
@property (nonatomic, strong) UIColor *outgoingBubbleColor;

/**
 *  Sets the background color of internal note bubbles.
 *
 *  @param internalNoteColor Defaults to zng_note_yellow
 */
@property (nonatomic, strong) UIColor * internalNoteColor;

/**
 *  Sets the text color of the incoming message text.
 *
 *  @param incomingTextColor Defaults to Zingle gray text color
 */
@property (nonatomic, strong) UIColor *incomingTextColor;

/**
 *  Sets the text color of the outgoing message text.
 *
 *  @param outgoingTextColor Defaults to Zingle gray text color
 */
@property (nonatomic ,strong) UIColor *outgoingTextColor;

/**
 *  Sets the text color of internal notes.
 *
 *  @param internalNoteTextColor Defaults to Zingle gray text color
 */
@property (nonatomic, strong) UIColor * internalNoteTextColor;

/**
 *  Sets the text color of the label on top of the message bubble.
 *
 *  @param authorTextColor Defaults to [UIColor lightGrayColor]
 */
@property (nonatomic, strong) UIColor *authorTextColor;

/**
 *  The font used for incoming and outgoing message text.
 *
 *  Defaults to Lato 17pt.
 */
@property (nonatomic, strong) UIFont * messageFont;

/**
 *  The font used for message input.
 *
 *  Defaults to Lato 14pt.
 */
@property (nonatomic, strong) UIFont * textInputFont;

/**
 *  The color of the send button when enabled.
 */
@property (nonatomic, strong, nullable) UIColor * sendButtonColor;

/**
 *  The font of the send button.
 */
@property (nonatomic, strong, nullable) UIFont * sendButtonFont;

/**
 *  Additional inset between the toolbar and the bottom most message bubble.
 *
 *  Defaults to 0.0
 */
@property (nonatomic) CGFloat additionalBottomInset;

/**
 *  Sets whether or not the messages should be automatically marked as read.
 *
 *  @param autoMarkAsReadEnabled If YES, then the messages are automatically marked as read.
 *  Default value is NO.
 */
@property (nonatomic, assign, getter=isAutoMarkAsReadEnabled) BOOL autoMarkAsReadEnabled;

#pragma mark - Methods to be overridden by subclasses to add functionality
- (NSArray<UIAlertAction *> *)alertActionsForDetailsButton;

/**
 *  Bar buttons for the top right "..." button.  Subclasses may choose to call this super implementation or provide just their own.
 */
- (NSArray<UIBarButtonItem *> *)rightBarButtonItems;

/**
 *  Returns the NSString to be used for the sender name for a message.  Nil will not show a name.
 *  Defaults to nil.
 */
- (NSString * _Nullable) nameForMessageAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  If this method returns YES, a timestamp will be displayed above the current message.
 *  The default implementation returns YES if more than five minutes has passed since the previous message.
 */
- (BOOL) shouldShowTimestampAboveIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Protected methods used by subclasses
- (ZNGEvent *) eventAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Abstract methods that must be overridden by subclasses
- (BOOL) weAreSendingOutbound;

NS_ASSUME_NONNULL_END

@end
