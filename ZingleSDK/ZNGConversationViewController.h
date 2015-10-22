//
//  ZNGConversationViewController.h
//  ZingleSDK
//
//  Copyright © 2015 Zingle.me. All rights reserved.
//

#import "ViewController.h"

@class ZNGMessageView;
@class ZNGArrowView;
@class ZNGConversation;

extern int const ZINGLE_ARROW_POSITION_BOTTOM;
extern int const ZINGLE_ARROW_POSITION_SIDE;

@interface ZNGConversationViewController : ViewController <UITextViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, retain) UIColor *inboundBackgroundColor, *outboundBackgroundColor, *inboundTextColor, *outboundTextColor, *eventBackgroundColor, *eventTextColor, *authorTextColor;
@property (nonatomic) int bodyPadding, messageHorziontalMargin, messageVerticalMargin, messageIndentAmount, cornerRadius, arrowOffset, arrowPosition, arrowBias;
@property (nonatomic, retain) UIFont *messageFont;
@property (nonatomic) CGSize arrowSize;
@property (nonatomic, retain) ZNGConversation *conversation;

- (id)initWithConversation:(ZNGConversation *)conversation;

- (ZNGMessageView *)addMessage:(NSString *)message withDirection:(NSString *)direction andTime:(NSString *)time;
- (void)setBackgroundColor:(UIColor *)backgroundColor;
- (void)clear;
- (void)refreshDisplay;
//- (void)addActivityView;

@end
