//
//  MessageView.h
//  Zingle
//
//  Copyright (c) 2014 Zingle.me. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZNGConversationViewController;

@interface ZNGMessageView : UIView

- (id)initWithViewController:(ZNGConversationViewController *)parentViewController;
- (void)setMessage:(NSString *)message withDirection:(NSString *)direction andTime:(NSString *)time;
- (void)setAssetUrls:(NSArray *)assetUrls;
- (void)setAuthor:(NSString *)author;
- (void)refresh;

@end
