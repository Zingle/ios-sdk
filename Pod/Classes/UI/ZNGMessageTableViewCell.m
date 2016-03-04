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
#import <SDWebImage/UIImageView+WebCache.h>

@interface ZNGMessageTableViewCell()

@property (weak, nonatomic) IBOutlet UIView *bodyView;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIView *attachmentsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachmentsViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachmentsViewTop;

@property (weak, nonatomic) IBOutlet ZNGArrowView *inboundTopArrow;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inboundTopArrowWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inboundTopArrowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inboundTopArrowOffset;

@property (weak, nonatomic) IBOutlet ZNGArrowView *outboundTopArrow;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *outboundTopArrowWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *outboundTopArrowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *outboundTopArrowOffset;

@property (weak, nonatomic) IBOutlet ZNGArrowView *inboundDownArrow;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inboundDownArrowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inboundDownArrowWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inboundDownArrowOffset;

@property (weak, nonatomic) IBOutlet ZNGArrowView *outboundDownArrow;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *outboundDownArrowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *outboundDownArrowWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *outboundDownArrowOffset;

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
    
    self.inboundTopArrow.color = self.bodyView.backgroundColor;
    self.inboundTopArrow.direction = ZNGArrowDirectionUp;
    
    self.outboundTopArrow.color = self.bodyView.backgroundColor;
    self.outboundTopArrow.direction = ZNGArrowDirectionUp;
    
    self.inboundDownArrow.color = self.bodyView.backgroundColor;
    self.inboundDownArrow.direction = ZNGArrowDirectionDown;
    
    self.outboundDownArrow.color = self.bodyView.backgroundColor;
    self.outboundDownArrow.direction = ZNGArrowDirectionDown;
    
    self.leftArrow.color = self.bodyView.backgroundColor;
    self.leftArrow.direction = ZNGArrowDirectionLeft;
    
    self.rightArrow.color = self.bodyView.backgroundColor;
    self.rightArrow.direction = ZNGArrowDirectionRight;
}

- (void) configureCellForMessage:(ZNGMessageViewModel *)messageViewModel withDirection:(NSString *)direction;
{
    NSString *body = messageViewModel.message.body;
    body = [body stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
    body = [body stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    body = [body stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"];
    self.messageTextView.text = body;
    
    if([self.messageTextView.text length] > 0) {
        self.attachmentsViewTop.constant = 0;
    } else {
        self.attachmentsViewTop.constant = -30;
    }

    self.attachmentsViewHeight.constant = 0;
    [[self.attachmentsView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    for( NSString *attachment in messageViewModel.message.attachments ) {
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0, 100, 100)];
        
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [imageView sd_setImageWithURL:[NSURL URLWithString:attachment] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            CGSize imageViewSize = [self imageSize:image scaledToWidth:self.attachmentsView.frame.size.width];
            imageView.frame = CGRectMake(0, 0, imageViewSize.width, imageViewSize.height);
        }];
        
        [self.attachmentsView addSubview:imageView];
        self.attachmentsViewHeight.constant = imageView.frame.size.height;
        
        break;
    }
    
    self.authorLabel.textColor = messageViewModel.authorTextColor;
    self.authorLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
    
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
            if ([direction isEqualToString:@"inbound"]) {
                self.inboundTopArrow.color = messageViewModel.inboundBackgroundColor;
                self.inboundTopArrowHeight.constant = [messageViewModel.arrowHeight floatValue];
                self.inboundTopArrowWidth.constant = [messageViewModel.arrowWidth floatValue];
                self.outboundTopArrowHeight.constant = 0;
                self.outboundTopArrowWidth.constant = 0;
                self.inboundTopArrowOffset.constant = [messageViewModel.arrowOffset floatValue];
            } else {
                self.outboundTopArrow.color = messageViewModel.outboundBackgroundColor;
                self.outboundTopArrowHeight.constant = [messageViewModel.arrowHeight floatValue];
                self.outboundTopArrowWidth.constant = [messageViewModel.arrowWidth floatValue];
                self.inboundTopArrowHeight.constant = 0;
                self.inboundTopArrowWidth.constant = 0;
                self.outboundTopArrowOffset.constant = -[messageViewModel.arrowOffset floatValue];
            }
            
            [self.inboundTopArrow setNeedsUpdateConstraints];
            [self.outboundTopArrow setNeedsUpdateConstraints];
            
            break;
            
        case ZNGArrowPositionBottom:
            if ([direction isEqualToString:@"inbound"]) {
                self.inboundDownArrow.color = messageViewModel.inboundBackgroundColor;
                self.inboundDownArrowHeight.constant = [messageViewModel.arrowHeight floatValue];
                self.inboundDownArrowWidth.constant = [messageViewModel.arrowWidth floatValue];
                self.outboundDownArrowHeight.constant = 0;
                self.outboundDownArrowWidth.constant = 0;
                self.inboundDownArrowOffset.constant = [messageViewModel.arrowOffset floatValue];
            } else {
                self.outboundDownArrow.color = messageViewModel.outboundBackgroundColor;
                self.outboundDownArrowHeight.constant = [messageViewModel.arrowHeight floatValue];
                self.outboundDownArrowWidth.constant = [messageViewModel.arrowWidth floatValue];
                self.inboundDownArrowHeight.constant = 0;
                self.inboundDownArrowWidth.constant = 0;
                self.outboundDownArrowOffset.constant = -[messageViewModel.arrowOffset floatValue];
            }
            
            [self.inboundDownArrow setNeedsUpdateConstraints];
            [self.outboundDownArrow setNeedsUpdateConstraints];
            
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
            
            [self.leftArrow setNeedsUpdateConstraints];
            [self.rightArrow setNeedsUpdateConstraints];

            break;
            
        default:
            break;
    }
    
    [self setNeedsDisplay];
}

-(CGSize)imageSize: (UIImage*) sourceImage scaledToWidth: (float) i_width
{
    float oldWidth = sourceImage.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    return CGSizeMake(newWidth, newHeight);
}

@end