//
//  ZNGConversationInputToolbar.m
//  Pods
//
//  Created by Jason Neel on 7/18/16.
//
//

#import "ZNGConversationInputToolbar.h"
#import "ZNGConversationToolbarContentView.h"

@implementation ZNGConversationInputToolbar

@dynamic delegate;

- (void) awakeFromNib
{
    [super awakeFromNib];
    self.preferredDefaultHeight = 79.0;
    self.barTintColor = [UIColor whiteColor];
}

- (JSQMessagesToolbarContentView *)loadToolbarContentView
{
    NSArray *nibViews = [[NSBundle bundleForClass:[self class]] loadNibNamed:NSStringFromClass([ZNGConversationToolbarContentView class])
                                                                                          owner:nil
                                                                                        options:nil];
    return nibViews.firstObject;
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

@end
