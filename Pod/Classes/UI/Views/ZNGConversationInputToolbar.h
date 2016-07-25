//
//  ZNGConversationInputToolbar.h
//  Pods
//
//  Created by Jason Neel on 7/18/16.
//
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>
#import "ZNGConversationToolbarContentView.h"

@class ZNGChannel;
@class ZNGConversationInputToolbar;

@protocol ZNGConversationInputToolbarDelegate <JSQMessagesInputToolbarDelegate>

NS_ASSUME_NONNULL_BEGIN

@optional
- (NSString *)displayNameForChannel:(ZNGChannel *)channel;

- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressUseTemplateButton:(id)sender;
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressInsertCustomFieldButton:(id)sender;
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressTriggerAutomationButton:(id)sender;
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressAttachImageButton:(id)sender;
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressAddInternalNoteButton:(id)sender;
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressChooseChannelButton:(id)sender;

@end

@interface ZNGConversationInputToolbar : JSQMessagesInputToolbar

@property (weak, nonatomic, nullable) id<ZNGConversationInputToolbarDelegate> delegate;

@property (weak, nonatomic, readonly) ZNGConversationToolbarContentView * contentView;

/**
 *  Defaults to an empty string.  Can be set to something like "No available channels".
 *  This value is ignored if self.currentChannel is non nil.
 */
@property (nonatomic, copy, nullable) NSString * noSelectedChannelText;

/**
 *  The currently selected channel.  Setting this will update the UI.
 */
@property (nonatomic, weak, nullable) ZNGChannel * currentChannel;

- (void) disableInput;
- (void) enableInput;

- (IBAction)didPressUseTemplate:(id)sender;
- (IBAction)didPressInsertCustomField:(id)sender;
- (IBAction)didPressTriggerAutomation:(id)sender;
- (IBAction)didPressAttachImage:(id)sender;
- (IBAction)didPressAddNote:(id)sender;

- (IBAction)didPressChannelSelectButton:(id)sender;

NS_ASSUME_NONNULL_END

@end
