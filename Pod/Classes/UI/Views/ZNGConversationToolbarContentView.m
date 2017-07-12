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
    
    UIColor * gray = [UIColor zng_gray];
    self.templateButton.tintColor = gray;
    self.customFieldButton.tintColor = gray;
    self.automationButton.tintColor = gray;
    self.imageButton.tintColor = gray;
    self.noteButton.tintColor = gray;
}

- (void) enableOrDisableAllEditingButtons:(BOOL)enabled
{
    self.templateButton.enabled = enabled;
    self.customFieldButton.enabled = enabled;
    self.automationButton.enabled = enabled;
    self.imageButton.enabled = enabled;
    self.noteButton.enabled = enabled;
}


- (void) collapseButtons:(BOOL)animated
{
    // This page intentionally left blank.
}

- (void) expandButtons:(BOOL)animated
{
    // This page intentionally left blank.
}

@end
