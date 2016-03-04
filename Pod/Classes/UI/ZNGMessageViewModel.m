//
//  ZNGMessageViewModel.m
//  Pods
//
//  Created by Ryan Farley on 3/3/16.
//
//

#import "ZNGMessageViewModel.h"

@implementation ZNGMessageViewModel

- (id)initWithMessage:(ZNGMessage *)message {
    self = [super init];
    if (self) {
        _message = message;
        _inboundBackgroundColor = [UIColor blueColor];
        _outboundBackgroundColor = [UIColor grayColor];
        _inboundTextColor = [UIColor whiteColor];
        _outboundTextColor = [UIColor whiteColor];
        _eventBackgroundColor = [UIColor blackColor];
        _eventTextColor = [UIColor whiteColor];
        _authorTextColor = [UIColor blueColor];
        
        _bodyPadding = @8;
        _messageVerticalMargin = @0;
        _messageHorziontalMargin = @0;
        _messageIndentAmount = @50;
        _cornerRadius = @10;
        _arrowOffset = @10;
        _arrowBias = @0;
        
        _messageFont = [UIFont systemFontOfSize:12];
        _fromName = @"received";
        _toName = @"me";
        _arrowWidth = @20;
        _arrowHeight = @10;
        _arrowPosition = ZNGArrowPositionBottom;
    }
    return self;
}

@end
