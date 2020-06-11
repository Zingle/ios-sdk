//
//  ZNGConversationTextView.h
//  Pods
//
//  Created by Jason Neel on 7/21/16.
//
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>

@interface ZNGConversationTextView : JSQMessagesComposerTextView

@property (nonatomic, assign) BOOL hideCursor;

/**
 * The background color to apply to highlights for text with the attributes specified in `attributeNamesToHighlight`.  Defaults to a light yellow.
 */
@property (nonatomic, strong, nullable) UIColor * attributeHighlightColor;

/**
 * The corner radius to apply to highlights due to `attributeNamesToHighlight`.  Defaults to 3.0.
 */
@property (nonatomic, assign) CGFloat attributeHighlightCornerRadius;

/**
 * Text attributes that should have highlights of `attributeHighlightColor` applied (for any value of the specified attributes)
 */
@property (nonatomic, strong, nullable) NSArray<NSString *> * attributeNamesToHighlight;

@end
