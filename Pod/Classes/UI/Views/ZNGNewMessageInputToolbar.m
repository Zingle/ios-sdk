//
//  ZNGNewMessageInputToolbar.m
//  Pods
//
//  Created by Jason Neel on 7/28/16.
//
//

#import "ZNGNewMessageInputToolbar.h"

@implementation ZNGNewMessageInputToolbar

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    UIButton * sendButton = self.contentView.rightBarButtonItem;
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    
    [self.contentView.templateButton addTarget:self action:@selector(didPressUseTemplate:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.customFieldButton addTarget:self action:@selector(didPressInsertCustomField:) forControlEvents:UIControlEventTouchUpInside];
}

- (JSQMessagesToolbarContentView *)loadToolbarContentView
{
    NSArray *nibViews = [[NSBundle bundleForClass:[self class]] loadNibNamed:@"ZNGNewMessageToolbarContentView"
                                                                       owner:nil
                                                                     options:nil];
    return nibViews.firstObject;
}

- (void) toggleSendButtonEnabled
{
    self.sendButton.enabled = [self.contentView.textView hasText];
}

@end
