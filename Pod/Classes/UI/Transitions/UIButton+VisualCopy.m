//
//  UIButton+VisualCopy.m
//  ZingleSDK
//
//  Created by Jason Neel on 2/9/18.
//

#import "UIButton+VisualCopy.h"

@implementation UIButton (VisualCopy)

- (UIButton *)nonInteractiveCopy
{
    UIButton * button = [[UIButton alloc] initWithFrame:self.frame];
    [button setTitle:[self titleForState:UIControlStateNormal] forState:UIControlStateNormal];
    [button setAttributedTitle:[self attributedTitleForState:UIControlStateNormal] forState:UIControlStateNormal];
    button.titleLabel.font = self.titleLabel.font;
    button.titleLabel.textColor = self.titleLabel.textColor;
    button.userInteractionEnabled = NO;
    
    return button;
}

@end
