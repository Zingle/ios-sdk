//
//  ZNGServiceConversationInputToolbar.m
//  Pods
//
//  Created by Jason Neel on 7/18/16.
//
//

#import "ZNGServiceConversationInputToolbar.h"
#import "ZNGServiceConversationToolbarContentView.h"
#import "UIColor+ZingleSDK.h"
#import "ZNGChannel.h"
#import "UIFont+Lato.h"

@import SBObjectiveCWrapper;

@implementation ZNGServiceConversationInputToolbar
{
    UIColor * normalBackgroundColor;
    UIColor * noteBackgroundColor;
    UIColor * originalTextViewTintColor;
    UIColor * normalButtonColor;
    UIColor * highlightedButtonColor;
    UIColor * messageTextColor;
    UIColor * noteTextColor;
    
    UIImage * sendButtonEnabled;
    UIImage * sendButtonDisabled;
    
    NSAttributedString * lastMessageText;
    NSAttributedString * lastNoteText;
}

@dynamic contentView;
@dynamic delegate;

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGServiceConversationInputToolbar class]];
    normalButtonColor = [UIColor colorNamed:@"ZNGToolbarButton" inBundle:bundle compatibleWithTraitCollection:nil];
    highlightedButtonColor = [UIColor colorNamed:@"ZNGLinkText" inBundle:bundle compatibleWithTraitCollection:nil];
    sendButtonEnabled = [UIImage imageNamed:@"sendEnabled" inBundle:bundle compatibleWithTraitCollection:nil];
    sendButtonDisabled = [UIImage imageNamed:@"sendDisabled" inBundle:bundle compatibleWithTraitCollection:nil];
    normalBackgroundColor = [UIColor whiteColor];
    noteBackgroundColor = [UIColor colorNamed:@"ZNGInternalNoteBackground" inBundle:bundle compatibleWithTraitCollection:nil];
    messageTextColor = [UIColor blackColor];
    noteTextColor = [UIColor blackColor];
    
    if (@available(iOS 13.0, *)) {
        normalBackgroundColor = [UIColor systemBackgroundColor];
        messageTextColor = [UIColor labelColor];
    }
    
    self.preferredDefaultHeight = 121.0;
    self.toolbarMode = TOOLBAR_MODE_MESSAGE;
    
    self.barTintColor = [UIColor whiteColor];
    
    UIButton * sendButton = self.contentView.rightBarButtonItem;
    self.sendButtonColor = [UIColor colorNamed:@"ZNGLinkText" inBundle:bundle compatibleWithTraitCollection:nil];
    self.sendButtonFont = [UIFont latoSemiBoldFontOfSize:17.0];
    CGSize sendButtonSize = [sendButton intrinsicContentSize];

    self.clipsToBounds = YES;
    
    self.contentView.textView.backgroundColor = [UIColor clearColor];
    self.contentView.textView.font = [UIFont latoFontOfSize:16.0];
    
    self.contentView.rightBarButtonItemWidth = sendButtonSize.width;
    
    self.currentChannel = nil;
    
    originalTextViewTintColor = self.contentView.textView.tintColor;
}

- (JSQMessagesToolbarContentView *)loadToolbarContentView
{
    NSArray *nibViews = [[NSBundle bundleForClass:[self class]] loadNibNamed:NSStringFromClass([ZNGServiceConversationToolbarContentView class])
                                                                                          owner:nil
                                                                                        options:nil];
    return nibViews.firstObject;
}

- (void) setInputEnabled:(BOOL)inputEnabled
{
    [self.contentView enableOrDisableAllEditingButtons:inputEnabled];
    [super setInputEnabled:inputEnabled];
}

- (void) setToolbarMode:(ZNGServiceConversationInputToolbarMode)toolbarMode
{
    if (toolbarMode == TOOLBAR_MODE_INTERNAL_NOTE) {
        self.contentView.textView.placeHolder = @"Write an internal note";
        self.contentView.backgroundColor = noteBackgroundColor;
        self.contentView.textView.textColor = noteTextColor;
        
        if (self.toolbarMode != TOOLBAR_MODE_INTERNAL_NOTE) {
            // We're going from non-note to note mode.  Preserve note text and restore message text.
            lastMessageText = self.contentView.textView.attributedText;
            self.contentView.textView.attributedText = lastNoteText;
        }
    } else {
        self.contentView.textView.placeHolder = @"Type a reply";
        self.contentView.backgroundColor = normalBackgroundColor;
        self.contentView.textView.textColor = messageTextColor;
        
        if (self.toolbarMode == TOOLBAR_MODE_INTERNAL_NOTE) {
            // We're going from note mode to non-note mode.  Preserve message text and restore note text.
            lastNoteText = self.contentView.textView.attributedText;
            self.contentView.textView.attributedText = lastMessageText;
        }
    }

    switch (toolbarMode) {
        case TOOLBAR_MODE_MESSAGE:
        {
            self.contentView.messageModeButton.hidden = NO;
            self.contentView.noteButton.hidden = NO;
            self.contentView.templateButton.hidden = NO;
            self.contentView.customFieldButton.hidden = YES;
            self.contentView.imageButton.hidden = NO;
            self.contentView.automationButton.hidden = NO;
            self.contentView.atButton.hidden = YES;
            
            self.contentView.messageModeButton.tintColor = highlightedButtonColor;
            self.contentView.noteButton.tintColor = normalButtonColor;

            self.contentView.channelSelectButton.hidden = NO;
            self.contentView.channelSelectArrow.hidden = NO;
            
            UIButton * sendButton = self.contentView.rightBarButtonItem;
            [sendButton setTitle:nil forState:UIControlStateNormal];
            [sendButton setImage:sendButtonEnabled forState:UIControlStateNormal];
            [sendButton setImage:sendButtonDisabled forState:UIControlStateDisabled];
            
            break;
        }
            
        case TOOLBAR_MODE_INTERNAL_NOTE:
        {
            self.contentView.messageModeButton.hidden = NO;
            self.contentView.noteButton.hidden = NO;
            self.contentView.templateButton.hidden = YES;
            self.contentView.customFieldButton.hidden = YES;
            self.contentView.imageButton.hidden = YES;
            self.contentView.automationButton.hidden = YES;
            self.contentView.atButton.hidden = NO;
            
            self.contentView.messageModeButton.tintColor = normalButtonColor;
            self.contentView.noteButton.tintColor = highlightedButtonColor;

            self.contentView.channelSelectButton.hidden = YES;
            self.contentView.channelSelectArrow.hidden = YES;
            
            UIButton * sendButton = self.contentView.rightBarButtonItem;
            [sendButton setTitle:@"Add" forState:UIControlStateNormal];
            [sendButton setImage:nil forState:UIControlStateNormal];
            [sendButton setImage:nil forState:UIControlStateDisabled];
            
            break;
        }
            
        case TOOLBAR_MODE_NEW_MESSAGE:
        {
            self.contentView.messageModeButton.hidden = YES;
            self.contentView.noteButton.hidden = YES;
            self.contentView.templateButton.hidden = NO;
            self.contentView.customFieldButton.hidden = NO;
            self.contentView.imageButton.hidden = NO;
            self.contentView.automationButton.hidden = YES;
            self.contentView.atButton.hidden = YES;
            
            self.contentView.channelSelectButton.hidden = YES;
            self.contentView.channelSelectArrow.hidden = YES;
            
            UIButton * sendButton = self.contentView.rightBarButtonItem;
            [sendButton setTitle:nil forState:UIControlStateNormal];
            [sendButton setImage:sendButtonEnabled forState:UIControlStateNormal];
            [sendButton setImage:sendButtonDisabled forState:UIControlStateDisabled];

            break;
        }
            
        case TOOLBAR_MODE_FORWARDING:
        {
            self.contentView.messageModeButton.hidden = YES;
            self.contentView.noteButton.hidden = YES;
            self.contentView.templateButton.hidden = YES;
            self.contentView.customFieldButton.hidden = YES;
            self.contentView.imageButton.hidden = YES;
            self.contentView.automationButton.hidden = YES;
            self.contentView.atButton.hidden = YES;
            
            self.contentView.channelSelectButton.hidden = YES;
            self.contentView.channelSelectArrow.hidden = YES;

            UIButton * sendButton = self.contentView.rightBarButtonItem;
            [sendButton setTitle:@"Forward" forState:UIControlStateNormal];
            [sendButton setImage:nil forState:UIControlStateNormal];
            [sendButton setImage:nil forState:UIControlStateDisabled];

            break;
        }
    }
    
    // Restore actions that tend to break themselves when buttons exist in stack views
    [self resetActions];
    
    _toolbarMode = toolbarMode;
}

// Restore actions that tend to break themselves when buttons exist in stack views
- (void) resetActions
{
    [self.contentView.messageModeButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.templateButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.customFieldButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.automationButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.imageButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.atButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.noteButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.messageModeButton addTarget:self action:@selector(didPressMessageModeButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.templateButton addTarget:self action:@selector(didPressUseTemplate:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.customFieldButton addTarget:self action:@selector(didPressInsertCustomField:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.automationButton addTarget:self action:@selector(didPressTriggerAutomation:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.imageButton addTarget:self action:@selector(didPressAttachImage:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.atButton addTarget:self action:@selector(didPressAtButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.noteButton addTarget:self action:@selector(didPressAddNote:) forControlEvents:UIControlEventTouchUpInside];
}

- (void) setCurrentChannel:(ZNGChannel *)currentChannel
{
    _currentChannel = currentChannel;
    [self updateDisplayForCurrentChannel];
}

- (void) setNoSelectedChannelText:(NSString *)noSelectedChannelText
{
    _noSelectedChannelText = [noSelectedChannelText copy];
    [self updateDisplayForCurrentChannel];
}

- (void) updateDisplayForCurrentChannel
{
    NSAttributedString * title = [self attributedStringForChannelSelectButton:self.currentChannel];
    [self.contentView.channelSelectButton setAttributedTitle:title forState:UIControlStateNormal];
    [self.contentView.channelSelectButton sizeToFit];
}

- (NSAttributedString *) attributedStringForChannelSelectButton:(ZNGChannel *)channel
{
    CGFloat fontPointSize = self.contentView.channelSelectButton.titleLabel.font.pointSize;
    
    // Use Lato if available in the bundle
    UIFont * boldFont = [UIFont latoBoldFontOfSize:fontPointSize];
    UIFont * font = [UIFont latoFontOfSize:fontPointSize];

    
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:@"Reply to:  " attributes:@{ NSFontAttributeName : boldFont,
                                                                                                                        NSForegroundColorAttributeName: [UIColor colorFromHexString:@"#6B6B6B"] }];
    NSString * valueString;
    
    if (channel != nil) {
        if ([self.delegate respondsToSelector:@selector(displayNameForChannel:)]) {
            valueString = [self.delegate displayNameForChannel:channel];
        } else {
            valueString = [channel displayValueUsingFormattedValue];
        }
    } else if (self.noSelectedChannelText != nil) {
        valueString = self.noSelectedChannelText;
    }
    
    if (valueString != nil) {
        NSAttributedString * attributedValueString = [[NSAttributedString alloc] initWithString:valueString attributes:@{ NSFontAttributeName : font }];
        [string appendAttributedString:attributedValueString];
    }
    
    return string;
}

#pragma mark - IBActions

- (IBAction)didPressMessageModeButton:(id)sender
{
    self.toolbarMode = TOOLBAR_MODE_MESSAGE;
}

- (IBAction)didPressUseTemplate:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(inputToolbar:didPressUseTemplateButton:)]) {
        [self.delegate inputToolbar:self didPressUseTemplateButton:sender];
    }
}

- (IBAction)didPressInsertCustomField:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(inputToolbar:didPressInsertCustomFieldButton:)]) {
        [self.delegate inputToolbar:self didPressInsertCustomFieldButton:sender];
    }
}

- (IBAction)didPressTriggerAutomation:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(inputToolbar:didPressTriggerAutomationButton:)]) {
        [self.delegate inputToolbar:self didPressTriggerAutomationButton:sender];
    }
}

- (IBAction)didPressAttachImage:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(inputToolbar:didPressAttachImageButton:)]) {
        [self.delegate inputToolbar:self didPressAttachImageButton:sender];
    }
}

- (IBAction)didPressAddNote:(id)sender
{
    self.toolbarMode = TOOLBAR_MODE_INTERNAL_NOTE;
}

- (IBAction)didPressChannelSelectButton:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(inputToolbar:didPressChooseChannelButton:)]) {
        [self.delegate inputToolbar:self didPressChooseChannelButton:sender];
    }
}

- (IBAction)didPressAtButton:(id)sender
{
    UITextView * textView = self.contentView.textView;
    NSRange selectedRange = textView.selectedRange;
    NSMutableAttributedString * mutableText = [textView.attributedText mutableCopy];
    
    // Insert text at the end of input if there is no cursor
    if (selectedRange.location == NSNotFound) {
        selectedRange = NSMakeRange([mutableText length], 0);
    }
    
    if (selectedRange.length > 0) {
        [mutableText deleteCharactersInRange:selectedRange];
    }
    
    NSAttributedString * atString = [[NSAttributedString alloc] initWithString:@"@"];
    [mutableText insertAttributedString:atString atIndex:selectedRange.location];
    
    if ((textView.delegate == nil) || ([textView.delegate textView:textView shouldChangeTextInRange:selectedRange replacementText:@"@"])) {
        UIFont * font = textView.font;
        textView.attributedText = mutableText;
        textView.font = font;
        [textView.delegate textViewDidChange:self.contentView.textView];
        [textView becomeFirstResponder];
    }
}

@end
