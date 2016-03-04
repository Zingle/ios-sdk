//
//  ZNGNewConvoViewController.h
//  Pods
//
//  Created by Ryan Farley on 3/2/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGConversation.h"
#import "ZNGMessageTableViewCell.h"

@interface ZNGNewConvoViewController : UIViewController <ZNGConversationDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) ZNGConversation *conversation;

@property (nonatomic, strong) UIColor *inboundBackgroundColor;
@property (nonatomic, strong) UIColor *outboundBackgroundColor;
@property (nonatomic, strong) UIColor *inboundTextColor;
@property (nonatomic, strong) UIColor *outboundTextColor;
@property (nonatomic, strong) UIColor *eventBackgroundColor;
@property (nonatomic, strong) UIColor *eventTextColor;
@property (nonatomic, strong) UIColor *authorTextColor;

@property (nonatomic, strong) NSNumber *bodyPadding;
@property (nonatomic, strong) NSNumber *messageVerticalMargin;
@property (nonatomic, strong) NSNumber *messageHorziontalMargin;
@property (nonatomic, strong) NSNumber *messageIndentAmount;
@property (nonatomic, strong) NSNumber *cornerRadius;
@property (nonatomic, strong) NSNumber *arrowOffset;
@property (nonatomic, strong) NSNumber *arrowBias;
@property (nonatomic, strong) NSNumber *arrowWidth;
@property (nonatomic, strong) NSNumber *arrowHeight;

@property (nonatomic, strong) UIFont *messageFont;
@property (nonatomic, strong) NSString *fromName;
@property (nonatomic, strong) NSString *toName;
@property (nonatomic) ZNGArrowPosition arrowPosition;

- (id)initWithConversation:(ZNGConversation *)conversation;

@end
