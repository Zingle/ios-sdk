//
//  ZNGConversationToolbarContentView.m
//  Pods
//
//  Created by Jason Neel on 7/18/16.
//
//

#import "ZNGConversationToolbarContentView.h"
#import "UIColor+ZingleSDK.h"

@implementation ZNGConversationToolbarContentView

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

@end
