//
//  ZNGMessagesLabel.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//


#import <UIKit/UIKit.h>

/**
 *  `ZNGMessagesLabel` is a subclass of `UILabel` that adds support for a `textInsets` property,
 *  which is similar to the `textContainerInset` property of `UITextView`.
 */
@interface ZNGMessagesLabel : UILabel

/**
 *  The inset of the text layout area within the label's content area. The default value is `UIEdgeInsetsZero`.
 *
 *  @discussion This property provides text margins for the text laid out in the label.
 *  The inset values provided must be greater than or equal to `0.0f`.
 */
@property (assign, nonatomic) UIEdgeInsets textInsets;

@end
