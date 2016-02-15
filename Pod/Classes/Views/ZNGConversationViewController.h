//
//  ZNGConversationViewController.h
//  ZingleSDK
//
//  Copyright © 2015 Zingle.me. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZNGMessageView;
@class ZNGArrowView;
@class ZNGConversation;
@class ZNGContact;

extern int const ZINGLE_ARROW_POSITION_BOTTOM;
extern int const ZINGLE_ARROW_POSITION_SIDE;

@interface ZNGConversationViewController : UIViewController <UITextViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, retain) UIColor *inboundBackgroundColor, *outboundBackgroundColor, *inboundTextColor, *outboundTextColor, *eventBackgroundColor, *eventTextColor, *authorTextColor;
@property (nonatomic) int bodyPadding, messageHorziontalMargin, messageVerticalMargin, messageIndentAmount, cornerRadius, arrowOffset, arrowPosition, arrowBias;
@property (nonatomic, retain) UIFont *messageFont;
@property (nonatomic, retain) NSString *fromName, *toName;
@property (nonatomic) CGSize arrowSize;
@property (nonatomic, retain) ZNGConversation *conversation;

- (id)initWithConversation:(ZNGConversation *)conversation;

- (id)initWithChannelTypeName:(NSString *)channelTypeName to:(NSString *)to;
- (id)initWithChannelTypeName:(NSString *)channelTypeName from:(NSString *)from;

+ (void)conversationViewControllerWithContact:(ZNGContact *)contact
                              withChannelName:(NSString *)channelName
                             withChannelValue:(NSString *)channelValue
                          withCompletionBlock:(void (^) (ZNGConversationViewController *viewController))completionBlock
                                   errorBlock:(void (^) (NSError *error))errorBlock;

- (void)setBackgroundColor:(UIColor *)backgroundColor;
- (void)clear;

@end
