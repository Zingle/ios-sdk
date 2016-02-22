//
//  ZNGMessageTableViewCell.m
//  Pods
//
//  Created by Ryan Farley on 2/22/16.
//
//

#import "ZNGMessageTableViewCell.h"

@implementation ZNGMessageTableViewCell

- (void)setBubbleColor:(UIColor *)backgroundColor{
    self.oTextView.backgroundColor = backgroundColor;
}

- (UIColor*)bubbleColor{
    return self.oTextView.backgroundColor;
}

- (void)awakeFromNib {
    self.oTextView.backgroundColor     = [UIColor clearColor];
    
    self.oTextView.contentInset        = UIEdgeInsetsZero;
    self.oTextView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
    self.oTextView.textContainer.lineFragmentPadding = 0;
    self.oTextView.clipsToBounds = NO;
    self.oTextView.layer.cornerRadius = 10.0f;
    
    self.oImageContainerView.layer.borderWidth = 1;
    self.oImageContainerView.layer.cornerRadius = self.oProfileImageView.frame.size.width / 2;
    
    self.oInitialsLabel.backgroundColor = [UIColor greenColor];
    self.oInitialsLabel.textColor       = [UIColor whiteColor];
    
    self.transform = CGAffineTransformMakeScale(1, -1);
}

- (void)setMessageModel:(ZNGMessage *)messageModel{
    
    self.oTextView.text   = messageModel.body;
}

- (CGSize)sizeThatFits:(CGSize)size{
    CGFloat fixedWidth = size.width - self.oFixedEdgeConstraint.constant - self.oAdjustableEdgeConstraint.constant;
    
    //Fit to textView
    CGSize newSize = [self.oTextView sizeThatFits:CGSizeMake(fixedWidth, size.height)];
    
    //Pad for outter view
    newSize = CGSizeMake(newSize.width, newSize.height + self.oTopConstraint.constant + self.oBottomConstraint.constant);
    
    
    CGFloat userInfoBlockHeight = self.oUserInfoTopConstraint.constant + self.oImageContainerView.frame.size.height + self.oUserInfoMiddleConstraint.constant + self.oTimeStampLabel.frame.size.height + self.oUserInfoBottomConstraint.constant;
    
    if(userInfoBlockHeight > newSize.height){
        newSize.height = userInfoBlockHeight;
    }
    
    if(floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        self.oBubbleMinWidth.constant = fixedWidth - 1;
    }
    
    return newSize;
}

@end
