//
//  ZNGConversationInputToolbar.h
//  Pods
//
//  Created by Jason Neel on 7/18/16.
//
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>

@class ZNGConversationInputToolbar;

@protocol ZNGConversationInputToolbarDelegate <JSQMessagesInputToolbarDelegate>

- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressUseTemplateButton:(id)sender;
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressInsertCustomFieldButton:(id)sender;
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressTriggerAutomationButton:(id)sender;
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressAttachImageButton:(id)sender;
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressAddInternalNoteButton:(id)sender;

@end

@interface ZNGConversationInputToolbar : JSQMessagesInputToolbar

@property (weak, nonatomic) id<ZNGConversationInputToolbarDelegate> delegate;

- (IBAction)didPressUseTemplate:(id)sender;
- (IBAction)didPressInsertCustomField:(id)sender;

@end
