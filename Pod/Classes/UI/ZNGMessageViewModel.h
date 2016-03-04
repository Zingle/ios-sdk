//
//  ZNGMessageViewModel.h
//  Pods
//
//  Created by Ryan Farley on 3/3/16.
//
//

#import <Foundation/Foundation.h>
#import "ZNGMessageTableViewCell.h"
#import "ZNGMessage.h"

@interface ZNGMessageViewModel : NSObject

@property (nonatomic, strong) ZNGMessage *message;

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

- (id)initWithMessage:(ZNGMessage *)message;

@end
