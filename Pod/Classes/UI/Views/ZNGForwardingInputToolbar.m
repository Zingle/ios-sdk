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
    
    if (@available(iOS 13.0, *)) {
        self.barTintColor = [UIColor systemBackgroundColor];
    } else {
        self.barTintColor = [UIColor whiteColor];
    }
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGForwardingInputToolbar class]];
    UIButton * sendButton = self.contentView.rightBarButtonItem;
    [sendButton setTitle:@"Forward" forState:UIControlStateNormal];
    self.sendButtonColor = [UIColor colorNamed:@"ZNGPositiveAction" inBundle:bundle compatibleWithTraitCollection:nil];
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
