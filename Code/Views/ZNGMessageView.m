//
//  MessageView.m
//  Zingle
//
//  Copyright (c) 2014 Zingle.me. All rights reserved.
//

#import "ZNGMessageView.h"
#import "ZNGConversationViewController.h"
#import "ZNGArrowView.h"
#import "ZNGMessage.h"
#import "ZNGMessageAttachment.h"

@interface ZNGMessageView()

@property (nonatomic, retain) ZNGConversationViewController *parentViewController;
@property (nonatomic, retain) UIView *bodyView, *arrowView;
@property (nonatomic, retain) NSString *direction;
@property (nonatomic, retain) ZNGMessage *message;
@property (nonatomic, retain) UILabel *timeLabel, *authorLabel;
@property (nonatomic, retain) UITextView *messageTextView;
@property (nonatomic, retain) ZNGArrowView *arrow;

@end

@implementation ZNGMessageView

- (id)initWithViewController:(ZNGConversationViewController *)parentViewController
{
    if( self = [super init] ) {
        self.parentViewController = parentViewController;
        
        self.backgroundColor = [UIColor clearColor];
        
        self.bodyView = [[UIView alloc] init];
        self.bodyView.layer.cornerRadius = self.parentViewController.cornerRadius;
        self.bodyView.clipsToBounds = YES;
        [self addSubview:self.bodyView];
        
        self.messageTextView = [[UITextView alloc] init];
        self.messageTextView.backgroundColor = [UIColor clearColor];
        [self.messageTextView setEditable:NO];
        [self.messageTextView setUserInteractionEnabled:NO];
        [self.messageTextView.textContainer setLineFragmentPadding:0];
        [self.messageTextView setTextContainerInset:UIEdgeInsetsZero];
        [self.bodyView addSubview:self.messageTextView];
        
        self.arrowView = [[UIView alloc] init];
        [self addSubview:self.arrowView];
        
        self.arrow = [[ZNGArrowView alloc] init];
        [self.arrowView addSubview:self.arrow];
        
        self.authorLabel = [[UILabel alloc] init];
        self.authorLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
        self.authorLabel.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
        [self addSubview:self.authorLabel];
    }
    return self;
}

- (void)setMessage:(ZNGMessage *)message withDirection:(NSString *)direction
{
    self.message = message;
    self.direction = direction;
    
    for( ZNGMessageAttachment *attachment in message.attachments ) {
        [attachment getImageWithCompletionBlock:^(UIImage *image) {
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            int bodyPadding = self.parentViewController.bodyPadding;
            imageView.frame = CGRectMake(bodyPadding, bodyPadding, self.bodyView.frame.size.width - (bodyPadding*2), self.bodyView.frame.size.height - (bodyPadding*2));
            
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [self.bodyView addSubview:imageView];
            
            
        } errorBlock:^(NSError *requestError) {
            NSLog(@"Could not load image. %@", requestError);
        }];
        
        break;
    }
    
    [self refresh];
}

- (NSString *)body
{
    NSString *body = self.message.body;
    body = [body stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
    body = [body stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    body = [body stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"];
    
    return body;
}

- (void)refresh
{    
    self.messageTextView.text = [self body];
    if( self.parentViewController.messageFont )
    {
        self.messageTextView.font = self.parentViewController.messageFont;
    }
    
    NSString *author;
    if( [self.direction isEqualToString:@"inbound"] )
    {
        author = @"Received";
        self.bodyView.backgroundColor = self.parentViewController.inboundBackgroundColor;
        self.messageTextView.textColor = self.parentViewController.inboundTextColor;
    }
    else if( [self.direction isEqualToString:@"outbound"] )
    {
        author = @"Me";
        self.bodyView.backgroundColor = self.parentViewController.outboundBackgroundColor;
        self.messageTextView.textColor = self.parentViewController.outboundTextColor;
    }
    
    self.arrow.color = self.bodyView.backgroundColor;
    
    self.bodyView.layer.cornerRadius = self.parentViewController.cornerRadius;

    int leftIndent = 0, rightIndent = 0;
    
    int messageHorizontalMargin = self.parentViewController.messageHorziontalMargin;
    int messageVerticalMargin = self.parentViewController.messageVerticalMargin;
    int bodyPadding = self.parentViewController.bodyPadding;
    
    if( [self.direction isEqualToString:@"outbound"] )
    {
        leftIndent = self.parentViewController.messageIndentAmount;
    }
    else if( [self.direction isEqualToString:@"inbound"] )
    {
        rightIndent = self.parentViewController.messageIndentAmount;
    }
    
    int bodyWidth = self.frame.size.width - (messageHorizontalMargin * 2) - leftIndent - rightIndent;
    int bodyX     = messageHorizontalMargin + leftIndent;
    
    if( self.parentViewController.arrowPosition == ZINGLE_ARROW_POSITION_SIDE &&
       ([self.direction isEqualToString:@"outbound"] ||
        [self.direction isEqualToString:@"inbound"]) )
    {
        bodyWidth -= self.parentViewController.arrowSize.width;
        
        if( [self.direction isEqualToString:@"inbound"] ) {
            bodyX += self.parentViewController.arrowSize.width;
        }
    }
    
    self.authorLabel.frame = CGRectMake(0, 0, 0, 0);
    
    if( author && ![author isEqualToString:@""] )
    {
        self.authorLabel.frame = CGRectMake(bodyX + self.parentViewController.cornerRadius, 0, bodyWidth - (self.parentViewController.cornerRadius * 2), 20);
        self.authorLabel.text = author;
        self.authorLabel.textColor = self.parentViewController.authorTextColor;
    }
    
    CGSize textViewSize = [self.messageTextView sizeThatFits:CGSizeMake(bodyWidth - (bodyPadding * 2), FLT_MAX)];
    
    self.messageTextView.frame = CGRectMake(bodyPadding, bodyPadding, bodyWidth - (bodyPadding * 2), textViewSize.height + bodyPadding);
    int messageViewBottom = self.messageTextView.frame.origin.y + self.messageTextView.frame.size.height;
    
    if( [self.message.attachments count] > 0 ) {
        messageViewBottom += 200;
    }
    
    self.bodyView.frame = CGRectMake(bodyX,
                                     self.authorLabel.frame.origin.y + self.authorLabel.frame.size.height,
                                     bodyWidth,
                                     messageViewBottom);
    
    
    
    CGRect arrowFrame = CGRectMake(0, 0, 0, 0);
    int arrowBottomHeight = 0;
    int arrowBias = -self.parentViewController.arrowBias;
    if( [self.direction isEqualToString:@"outbound"] ||
        [self.direction isEqualToString:@"inbound"])
    {
        if( self.parentViewController.arrowPosition == ZINGLE_ARROW_POSITION_BOTTOM ) {
            arrowFrame = CGRectMake(self.bodyView.frame.origin.x + self.parentViewController.cornerRadius,
                                self.bodyView.frame.origin.y + self.bodyView.frame.size.height,
                                self.bodyView.frame.size.width - (self.parentViewController.cornerRadius * 2),
                                self.parentViewController.arrowSize.height);
        
            int arrowX = self.parentViewController.arrowOffset;
            if( [self.direction isEqualToString:@"outbound"] ) {
                arrowX = arrowFrame.size.width - self.parentViewController.arrowSize.width - self.parentViewController.arrowOffset;
            }
        
            self.arrow.frame = CGRectMake(arrowX, 0, self.parentViewController.arrowSize.width, self.parentViewController.arrowSize.height);
            arrowBottomHeight = self.parentViewController.arrowSize.height;
        } else {
            int arrowFrameX = self.bodyView.frame.origin.x - self.parentViewController.arrowSize.width;
            NSString *arrowDirection = @"left";
            if( [self.direction isEqualToString:@"outbound"] ) {
                arrowFrameX = self.bodyView.frame.origin.x + self.bodyView.frame.size.width;
                arrowDirection = @"right";
            }
            
            arrowFrame = CGRectMake(arrowFrameX, self.bodyView.frame.origin.y + self.parentViewController.cornerRadius, self.parentViewController.arrowSize.width, self.bodyView.frame.size.height - (self.parentViewController.cornerRadius * 2) );
            
            self.arrow.frame = CGRectMake(0, arrowFrame.size.height - self.parentViewController.arrowOffset - self.parentViewController.arrowSize.height, self.parentViewController.arrowSize.width, self.parentViewController.arrowSize.height);
            self.arrow.direction = arrowDirection;
        }
    }
    
    
    if( [self.direction isEqualToString:@"outbound"] ) {
        arrowBias = -arrowBias;
    }
    
    self.arrowView.frame = arrowFrame;
    self.arrow.bias = arrowBias;
    self.arrowView.clipsToBounds = YES;

    self.frame = CGRectMake(0,
                            self.frame.origin.y,
                            self.frame.size.width,
                            self.bodyView.frame.origin.y +
                            self.bodyView.frame.size.height +
                               arrowBottomHeight +
                               messageVerticalMargin);
}

@end
