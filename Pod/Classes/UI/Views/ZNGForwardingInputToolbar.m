//
//  ZNGForwardingInputToolbar.m
//  Pods
//
//  Created by Jason Neel on 12/2/16.
//
//

#import "ZNGForwardingInputToolbar.h"
#import "UIColor+ZingleSDK.h"
#import "UIFont+Lato.h"

@implementation ZNGForwardingInputToolbar

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    UIButton * sendButton = self.contentView.rightBarButtonItem;
    [sendButton setTitle:@"Forward" forState:UIControlStateNormal];
    self.sendButtonColor = [UIColor zng_green];
    self.sendButtonFont = [UIFont latoSemiBoldFontOfSize:17.0];
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
