//
//  UIView+ZNGMessages.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <UIKit/UIKit.h>

@interface UIView (ZNGMessages)

/**
 *  Pins the subview of the receiver to the edge of its frame, as specified by the given attribute, by adding a layout constraint.
 *
 *  @param subview   The subview to which the receiver will be pinned.
 *  @param attribute The layout constraint attribute specifying one of `NSLayoutAttributeBottom`, `NSLayoutAttributeTop`, `NSLayoutAttributeLeading`, `NSLayoutAttributeTrailing`.
 */
- (void)zng_pinSubview:(UIView *)subview toEdge:(NSLayoutAttribute)attribute;

/**
 *  Pins all edges of the specified subview to the receiver.
 *
 *  @param subview The subview to which the receiver will be pinned.
 */
- (void)zng_pinAllEdgesOfSubview:(UIView *)subview;

@end
