//
//  ZNGNewMessageInputToolbar.m
//  Pods
//
//  Created by Jason Neel on 7/28/16.
//
//

#import "ZNGNewMessageInputToolbar.h"
#import "ZNGServiceConversationToolbarContentView.h"

@implementation ZNGNewMessageInputToolbar

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    if (@available(iOS 13.0, *)) {
        self.barTintColor = [UIColor systemBackgroundColor];
    }
    
    UIButton * sendButton = self.contentView.rightBarButtonItem;
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    
    [self.contentView.templateButton addTarget:self action:@selector(didPressUseTemplate:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.customFieldButton addTarget:self action:@selector(didPressInsertCustomField:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.imageButton addTarget:self action:@selector(didPressAttachImage:) forControlEvents:UIControlEventTouchUpInside];
}

- (JSQMessagesToolbarContentView *)loadToolbarContentView
{
    NSArray *nibViews = [[NSBundle bundleForClass:[self class]] loadNibNamed:@"ZNGNewMessageToolbarContentView"
                                                                       owner:nil
                                                                     options:nil];
    return nibViews.firstObject;
}

@end
