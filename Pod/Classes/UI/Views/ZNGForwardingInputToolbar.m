//
//  ZNGForwardingInputToolbar.m
//  Pods
//
//  Created by Jason Neel on 12/2/16.
//
//

#import "ZNGForwardingInputToolbar.h"

@implementation ZNGForwardingInputToolbar

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    UIButton * sendButton = self.contentView.rightBarButtonItem;
    [sendButton setTitle:@"Forward" forState:UIControlStateNormal];
    CGSize sendButtonSize = [sendButton intrinsicContentSize];
    self.contentView.rightBarButtonItemWidth = sendButtonSize.width;
}

- (JSQMessagesToolbarContentView *)loadToolbarContentView
{
    NSArray *nibViews = [[NSBundle bundleForClass:[self class]] loadNibNamed:@"ZNGMessageForwardToolbarContentView"
                                                                       owner:nil
                                                                     options:nil];
    return nibViews.firstObject;
}

@end
