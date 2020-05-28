//
//  ZNGConversationToolbarContentView.m
//  Pods
//
//  Created by Jason Neel on 7/18/16.
//
//

#import "ZNGConversationToolbarContentView.h"
#import "UIColor+ZingleSDK.h"
#import "UIFont+Lato.h"

@implementation ZNGConversationToolbarContentView

@dynamic textView;

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGConversationToolbarContentView class]];
    UIColor * buttonColor = [UIColor colorNamed:@"ZNGToolbarButton" inBundle:bundle compatibleWithTraitCollection:nil];
    self.templateButton.tintColor = buttonColor;
    self.customFieldButton.tintColor = buttonColor;
    self.automationButton.tintColor = buttonColor;
    self.imageButton.tintColor = buttonColor;
    self.noteButton.tintColor = buttonColor;
    
    if (@available(iOS 13.0, *)) {
        self.textView.backgroundColor = [UIColor systemBackgroundColor];
    }
}

- (void) enableOrDisableAllEditingButtons:(BOOL)enabled
{
    self.messageModeButton.enabled = enabled;
    self.templateButton.enabled = enabled;
    self.customFieldButton.enabled = enabled;
    self.automationButton.enabled = enabled;
    self.imageButton.enabled = enabled;
    self.noteButton.enabled = enabled;
}

@end
