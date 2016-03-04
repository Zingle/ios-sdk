//
//  ZNGMessageTableViewCell.m
//  Pods
//
//  Created by Ryan Farley on 3/2/16.
//
//

#import "ZNGMessageTableViewCell.h"
#import "ZNGArrowView.h"
#import "ZNGMessageViewModel.h"

@interface ZNGMessageTableViewCell()

@property (weak, nonatomic) IBOutlet UIView *bodyView;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;

@property (weak, nonatomic) IBOutlet ZNGArrowView *upArrow;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *upArrowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *upArrowWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *upArrowOffset;

@property (weak, nonatomic) IBOutlet ZNGArrowView *downArrow;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *downArrowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *downArrowWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *downArrowOffset;

@property (weak, nonatomic) IBOutlet ZNGArrowView *leftArrow;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftArrowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftArrowWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftArrowOffset;

@property (weak, nonatomic) IBOutlet ZNGArrowView *rightArrow;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightArrowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightArrowWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightArrowOffset;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftHorizontalMargin;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightHorizontalMargin;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalMargin;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bodyPaddingTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bodyPaddingLeft;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bodyPaddingRight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bodyPaddingBottom;

@end

@implementation ZNGMessageTableViewCell

+ (NSString *)reuseIdentifier
{
    return @"ZNGMessageTableViewCell";
}

- (void)awakeFromNib
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.upArrow.color = self.bodyView.backgroundColor;
    self.upArrow.direction = ZNGArrowDirectionUp;
    
    self.downArrow.color = self.bodyView.backgroundColor;
    self.downArrow.direction = ZNGArrowDirectionDown;
    
    self.leftArrow.color = self.bodyView.backgroundColor;
    self.leftArrow.direction = ZNGArrowDirectionLeft;
    
    self.rightArrow.color = self.bodyView.backgroundColor;
    self.rightArrow.direction = ZNGArrowDirectionRight;
}

- (void) configureCellForMessage:(ZNGMessageViewModel *)messageViewModel withDirection:(NSString *)direction;
{
//    self.messageTextView.text = messageViewModel.message.body;
    self.authorLabel.textColor = messageViewModel.authorTextColor;
    self.bodyPaddingTop.constant = self.bodyPaddingBottom.constant = self.bodyPaddingLeft.constant = self.bodyPaddingRight.constant = [messageViewModel.bodyPadding floatValue];
    self.bodyView.layer.cornerRadius = [messageViewModel.cornerRadius floatValue];
    
    if ([direction isEqualToString:@"inbound"]) {
        self.bodyView.backgroundColor = messageViewModel.inboundBackgroundColor;
        self.messageTextView.textColor = messageViewModel.inboundTextColor;
        self.authorLabel.text = messageViewModel.toName;
        self.leftHorizontalMargin.constant = [messageViewModel.messageHorziontalMargin floatValue];
        self.rightHorizontalMargin.constant = [messageViewModel.messageIndentAmount floatValue] + [messageViewModel.messageHorziontalMargin floatValue];
    } else {
        self.bodyView.backgroundColor = messageViewModel.outboundBackgroundColor;
        self.messageTextView.textColor = messageViewModel.outboundTextColor;
        self.authorLabel.text = messageViewModel.fromName;
        self.leftHorizontalMargin.constant = [messageViewModel.messageIndentAmount floatValue] + [messageViewModel.messageHorziontalMargin floatValue];
        self.rightHorizontalMargin.constant = [messageViewModel.messageHorziontalMargin floatValue];
    }
    
    self.verticalMargin.constant = [messageViewModel.messageVerticalMargin floatValue];
    
    switch (messageViewModel.arrowPosition) {
        case ZNGArrowPositionTop:
            self.upArrowHeight.constant = [messageViewModel.arrowHeight floatValue];
            self.upArrowWidth.constant = [messageViewModel.arrowWidth floatValue];
            
            if ([direction isEqualToString:@"inbound"]) {
                self.upArrow.color = messageViewModel.inboundBackgroundColor;
                self.upArrowOffset.constant = [messageViewModel.arrowOffset floatValue];
            } else {
                self.upArrow.color = messageViewModel.outboundBackgroundColor;
                self.upArrowOffset.constant = self.frame.size.width - [messageViewModel.arrowOffset floatValue] - [messageViewModel.arrowWidth floatValue] - 16;
            }
            
            break;
            
        case ZNGArrowPositionBottom:
            self.downArrowHeight.constant = [messageViewModel.arrowHeight floatValue];
            self.downArrowWidth.constant = [messageViewModel.arrowWidth floatValue];
            
            if ([direction isEqualToString:@"inbound"]) {
                self.downArrow.color = messageViewModel.inboundBackgroundColor;
                self.downArrowOffset.constant = -self.frame.size.width + [messageViewModel.arrowOffset floatValue] + [messageViewModel.arrowWidth floatValue] + 16;
            } else {
                self.downArrow.color = messageViewModel.outboundBackgroundColor;
                self.downArrowOffset.constant = -[messageViewModel.arrowOffset floatValue];
            }
            
            break;
            
        case ZNGArrowPositionSide:
            if ([direction isEqualToString:@"inbound"]) {
                self.leftArrow.color = messageViewModel.inboundBackgroundColor;
                self.leftArrowHeight.constant = [messageViewModel.arrowHeight floatValue];
                self.leftArrowWidth.constant = [messageViewModel.arrowWidth floatValue];
                self.rightArrowHeight.constant = 0;
                self.rightArrowWidth.constant = 0;
                self.leftArrowOffset.constant = -[messageViewModel.arrowOffset floatValue];
            } else {
                self.rightArrow.color = messageViewModel.outboundBackgroundColor;
                self.rightArrowHeight.constant = [messageViewModel.arrowHeight floatValue];
                self.rightArrowWidth.constant = [messageViewModel.arrowWidth floatValue];
                self.leftArrowHeight.constant = 0;
                self.leftArrowWidth.constant = 0;
                self.rightArrowOffset.constant = -[messageViewModel.arrowOffset floatValue];
            }

            break;
            
        default:
            break;
    }
    
    [self setNeedsDisplay];
}

@end