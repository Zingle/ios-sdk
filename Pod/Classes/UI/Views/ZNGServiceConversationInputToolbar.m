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
    UIColor * originalTextViewTintColor;
}

@dynamic contentView;
@dynamic delegate;

- (void) awakeFromNib
{
    [super awakeFromNib];
    self.preferredDefaultHeight = 121.0;
    self.toolbarMode = TOOLBAR_MODE_MESSAGE;
    
    self.barTintColor = [UIColor whiteColor];
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGServiceConversationInputToolbar class]];
    UIButton * sendButton = self.contentView.rightBarButtonItem;
    [sendButton setTitle:@"Reply" forState:UIControlStateNormal];
    self.sendButtonColor = [UIColor colorNamed:@"ZNGPositiveAction" inBundle:bundle compatibleWithTraitCollection:nil];
    self.sendButtonFont = [UIFont latoSemiBoldFontOfSize:17.0];
    CGSize sendButtonSize = [sendButton intrinsicContentSize];

    self.clipsToBounds = YES;
    
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
    _toolbarMode = toolbarMode;
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGServiceConversationInputToolbar class]];
    UIColor * normalButtonColor = [UIColor colorNamed:@"ZNGToolbarButton" inBundle:bundle compatibleWithTraitCollection:nil];
    UIColor * highlightedButtonColor = [UIColor colorNamed:@"ZNGLinkText" inBundle:bundle compatibleWithTraitCollection:nil];

    switch (toolbarMode) {
        case TOOLBAR_MODE_MESSAGE:
        {
            self.contentView.messageModeButton.hidden = NO;
            self.contentView.noteButton.hidden = NO;
            self.contentView.templateButton.hidden = NO;
            self.contentView.customFieldButton.hidden = YES;
            self.contentView.imageButton.hidden = NO;
            self.contentView.automationButton.hidden = NO;
            
            self.contentView.messageModeButton.tintColor = highlightedButtonColor;
            self.contentView.noteButton.tintColor = normalButtonColor;

            self.contentView.channelSelectButton.hidden = NO;
            self.contentView.channelSelectArrow.hidden = NO;
            
            UIButton * sendButton = self.contentView.rightBarButtonItem;
            [sendButton setTitle:@"Reply" forState:UIControlStateNormal];
            
            return;
        }
            
        case TOOLBAR_MODE_INTERNAL_NOTE:
        {
            self.contentView.messageModeButton.hidden = NO;
            self.contentView.noteButton.hidden = NO;
            self.contentView.templateButton.hidden = YES;
            self.contentView.customFieldButton.hidden = YES;
            self.contentView.imageButton.hidden = YES;
            self.contentView.automationButton.hidden = YES;
            
            self.contentView.messageModeButton.tintColor = normalButtonColor;
            self.contentView.noteButton.tintColor = highlightedButtonColor;

            self.contentView.channelSelectButton.hidden = YES;
            self.contentView.channelSelectArrow.hidden = YES;
            
            UIButton * sendButton = self.contentView.rightBarButtonItem;
            [sendButton setTitle:@"Add" forState:UIControlStateNormal];
            
            return;
        }
            
        case TOOLBAR_MODE_NEW_MESSAGE:
        {
            self.contentView.messageModeButton.hidden = YES;
            self.contentView.noteButton.hidden = YES;
            self.contentView.templateButton.hidden = NO;
            self.contentView.customFieldButton.hidden = NO;
            self.contentView.imageButton.hidden = NO;
            self.contentView.automationButton.hidden = YES;
            
            self.contentView.channelSelectButton.hidden = YES;
            self.contentView.channelSelectArrow.hidden = YES;
            
            UIButton * sendButton = self.contentView.rightBarButtonItem;
            [sendButton setTitle:@"Send" forState:UIControlStateNormal];
            
            return;
        }
            
        case TOOLBAR_MODE_FORWARDING:
        {
            self.contentView.messageModeButton.hidden = YES;
            self.contentView.noteButton.hidden = YES;
            self.contentView.templateButton.hidden = YES;
            self.contentView.customFieldButton.hidden = YES;
            self.contentView.imageButton.hidden = YES;
            self.contentView.automationButton.hidden = YES;
            
            self.contentView.channelSelectButton.hidden = YES;
            self.contentView.channelSelectArrow.hidden = YES;

            UIButton * sendButton = self.contentView.rightBarButtonItem;
            [sendButton setTitle:@"Forward" forState:UIControlStateNormal];
            
            return;
        }
    }
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
    if ([self.delegate respondsToSelector:@selector(inputToolbar:didPressMessageModeButton:)]) {
        [self.delegate inputToolbar:self didPressMessageModeButton:sender];
    }
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
    if ([self.delegate respondsToSelector:@selector(inputToolbar:didPressAddInternalNoteButton:)]) {
        [self.delegate inputToolbar:self didPressAddInternalNoteButton:sender];
    }
}

- (IBAction)didPressChannelSelectButton:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(inputToolbar:didPressChooseChannelButton:)]) {
        [self.delegate inputToolbar:self didPressChooseChannelButton:sender];
    }
}

@end
