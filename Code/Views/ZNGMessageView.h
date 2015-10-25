//
//  MessageView.h
//  Zingle
//
//  Copyright (c) 2014 Zingle.me. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZNGConversationViewController;
@class ZNGMessage;

@interface ZNGMessageView : UIView

- (id)initWithViewController:(ZNGConversationViewController *)parentViewController;
- (void)setMessage:(ZNGMessage *)message withDirection:(NSString *)direction;
- (void)refresh;

@end
