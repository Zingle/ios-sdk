//
//  ZNGConversationInputToolbar.h
//  Pods
//
//  Created by Jason Neel on 7/18/16.
//
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>

@class ZNGChannel;
@class ZNGConversationInputToolbar;
@class ZNGConversationToolbarContentView;

@protocol ZNGConversationInputToolbarDelegate <JSQMessagesInputToolbarDelegate>

@optional
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressUseTemplateButton:(id)sender;
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressInsertCustomFieldButton:(id)sender;
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressTriggerAutomationButton:(id)sender;
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressAttachImageButton:(id)sender;
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressAddInternalNoteButton:(id)sender;

- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didSelectChannel:(ZNGChannel *)channel;

@end

@interface ZNGConversationInputToolbar : JSQMessagesInputToolbar

@property (weak, nonatomic) id<ZNGConversationInputToolbarDelegate> delegate;

@property (weak, nonatomic, readonly) ZNGConversationToolbarContentView * contentView;

/**
 *  The currently selected channel.  Setting this will update the UI.  This property is KVO compliant when the user selects a channel.
 */
@property (nonatomic, strong, nullable) ZNGChannel * currentChannel;

- (IBAction)didPressUseTemplate:(id)sender;
- (IBAction)didPressInsertCustomField:(id)sender;
- (IBAction)didPressTriggerAutomation:(id)sender;
- (IBAction)didPressAttachImage:(id)sender;
- (IBAction)didPressAddNote:(id)sender;

- (IBAction)didPressChannelSelectButton:(id)sender;

@end
