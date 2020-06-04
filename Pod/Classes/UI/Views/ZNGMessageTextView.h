//
//  ZNGMessageTextView.h
//  ZingleSDK
//
//  Created by Jason Neel on 6/3/20.
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZNGMessageTextView : JSQMessagesCellTextView

/**
 * The highlight color to be applied under text with a mentions attribute.  Defaults to a light yellow.
 */
@property (nonatomic, strong, nullable) UIColor * mentionHighlightColor;

/**
 The corner radius of mention highlights.  Defaults to 3.0.
 */
@property (nonatomic, assign) CGFloat mentionHighlightCornerRadius;

/**
 * Extra space to highlight below and to the left of highlighted mentions.  Defaults to 3.0.
 */
@property (nonatomic, assign) CGFloat highlightPadding;

@end

NS_ASSUME_NONNULL_END
