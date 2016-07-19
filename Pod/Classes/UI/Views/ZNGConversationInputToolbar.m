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
    self.preferredDefaultHeight = 80.0;
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
    [self.delegate inputToolbar:self didPressUseTemplateButton:sender];
}

- (IBAction)didPressInsertCustomField:(id)sender
{
    [self.delegate inputToolbar:self didPressInsertCustomFieldButton:sender];
}

- (IBAction)didPressTriggerAutomation:(id)sender
{
    [self.delegate inputToolbar:self didPressTriggerAutomationButton:sender];
}

- (IBAction)didPressAttachImage:(id)sender
{
    [self.delegate inputToolbar:self didPressAttachImageButton:sender];
}

@end
