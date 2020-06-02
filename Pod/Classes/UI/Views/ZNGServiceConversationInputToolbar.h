//
//  ZNGServiceConversationInputToolbar.h
//  Pods
//
//  Created by Jason Neel on 7/18/16.
//
//

#import <ZingleSDK/ZNGConversationInputToolbar.h>
#import <ZingleSDK/ZNGServiceConversationToolbarContentView.h>

@class ZNGChannel;
@class ZNGServiceConversationInputToolbar;

typedef enum {
    TOOLBAR_MODE_MESSAGE,
    TOOLBAR_MODE_INTERNAL_NOTE,
    TOOLBAR_MODE_NEW_MESSAGE,
    TOOLBAR_MODE_FORWARDING
} ZNGServiceConversationInputToolbarMode;

@protocol ZNGServiceConversationInputToolbarDelegate <ZNGConversationInputToolbarDelegate>

NS_ASSUME_NONNULL_BEGIN

@optional
- (NSString *)displayNameForChannel:(ZNGChannel *)channel;

- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressMessageModeButton:(id)sender;
- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressUseTemplateButton:(id)sender;
- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressInsertCustomFieldButton:(id)sender;
- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressTriggerAutomationButton:(id)sender;
- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressAddInternalNoteButton:(id)sender;
- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressChooseChannelButton:(id)sender;

@end

@interface ZNGServiceConversationInputToolbar : ZNGConversationInputToolbar <UIGestureRecognizerDelegate>

@property (weak, nonatomic, nullable) id<ZNGServiceConversationInputToolbarDelegate> delegate;

@property (weak, nonatomic, readonly) ZNGServiceConversationToolbarContentView * contentView;

/**
 *  Defaults to an empty string.  Can be set to something like "No available channels".
 *  This value is ignored if self.currentChannel is non nil.
 */
@property (nonatomic, copy, nullable) NSString * noSelectedChannelText;

/**
 *  The currently selected channel.  Setting this will update the UI.
 */
@property (nonatomic, weak, nullable) ZNGChannel * currentChannel;

/**
 * The current toolbar mode, e.g. messaging, internal note, or message forwarding.  This will affect the button sets and button highlighting.
 * Defaults to `TOOLBAR_MODE_MESSAGE`
 */
@property (nonatomic, assign) ZNGServiceConversationInputToolbarMode toolbarMode;

- (IBAction)didPressMessageModeButton:(id)sender;
- (IBAction)didPressUseTemplate:(id)sender;
- (IBAction)didPressInsertCustomField:(id)sender;
- (IBAction)didPressTriggerAutomation:(id)sender;
- (IBAction)didPressAttachImage:(id)sender;
- (IBAction)didPressAddNote:(id)sender;

- (IBAction)didPressChannelSelectButton:(id)sender;

NS_ASSUME_NONNULL_END

@end
