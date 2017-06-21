//
//  ZNGServiceConversationInputToolbar.h
//  Pods
//
//  Created by Jason Neel on 7/18/16.
//
//

#import <ZingleSDK/ZNGConversationInputToolbar.h>
#import "ZNGConversationToolbarContentView.h"

@class ZNGChannel;
@class ZNGServiceConversationInputToolbar;

@protocol ZNGServiceConversationInputToolbarDelegate <ZNGConversationInputToolbarDelegate>

NS_ASSUME_NONNULL_BEGIN

@optional
- (NSString *)displayNameForChannel:(ZNGChannel *)channel;

- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressUseTemplateButton:(id)sender;
- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressInsertCustomFieldButton:(id)sender;
- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressTriggerAutomationButton:(id)sender;
- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressAddInternalNoteButton:(id)sender;
- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressChooseChannelButton:(id)sender;

@end

@interface ZNGServiceConversationInputToolbar : ZNGConversationInputToolbar

@property (weak, nonatomic, nullable) id<ZNGServiceConversationInputToolbarDelegate> delegate;

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

- (IBAction)didPressUseTemplate:(id)sender;
- (IBAction)didPressInsertCustomField:(id)sender;
- (IBAction)didPressTriggerAutomation:(id)sender;
- (IBAction)didPressAttachImage:(id)sender;
- (IBAction)didPressAddNote:(id)sender;

- (IBAction)didPressChannelSelectButton:(id)sender;

- (void) collapseInputButtons;

NS_ASSUME_NONNULL_END

@end
