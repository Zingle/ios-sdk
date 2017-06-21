//
//  ZNGServiceConversationInputToolbar.m
//  Pods
//
//  Created by Jason Neel on 7/18/16.
//
//

#import "ZNGServiceConversationInputToolbar.h"
#import "ZNGConversationToolbarContentView.h"
#import "UIColor+ZingleSDK.h"
#import "ZNGChannel.h"
#import "UIFont+Lato.h"
#import "ZNGLogging.h"

@implementation ZNGServiceConversationInputToolbar

@dynamic contentView;
@dynamic delegate;

- (void) awakeFromNib
{
    [super awakeFromNib];
    self.preferredDefaultHeight = 77.0;
    
    self.barTintColor = [UIColor whiteColor];
    
    UIButton * sendButton = self.contentView.rightBarButtonItem;
    [sendButton setTitle:@"Reply" forState:UIControlStateNormal];
    self.sendButtonColor = [UIColor zng_green];
    self.sendButtonFont = [UIFont latoSemiBoldFontOfSize:17.0];
    CGSize sendButtonSize = [sendButton intrinsicContentSize];
    
    [self.contentView.revealButton addTarget:self action:@selector(didPressRevealButton:) forControlEvents:UIControlEventTouchUpInside];

    self.clipsToBounds = YES;
    
    self.contentView.textView.font = [UIFont latoFontOfSize:16.0];
    
    self.contentView.rightBarButtonItemWidth = sendButtonSize.width;
    
    self.currentChannel = nil;
}

- (JSQMessagesToolbarContentView *)loadToolbarContentView
{
    NSArray *nibViews = [[NSBundle bundleForClass:[self class]] loadNibNamed:NSStringFromClass([ZNGConversationToolbarContentView class])
                                                                                          owner:nil
                                                                                        options:nil];
    return nibViews.firstObject;
}

- (void) setInputEnabled:(BOOL)inputEnabled
{
    [self.contentView enableOrDisableAllEditingButtons:inputEnabled];
    [super setInputEnabled:inputEnabled];
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

- (IBAction)didPressRevealButton:(id)sender
{
    [self.contentView expandButtons:YES];
}

- (void) collapseInputButtons
{
    [self.contentView collapseButtons:YES];
}

@end
