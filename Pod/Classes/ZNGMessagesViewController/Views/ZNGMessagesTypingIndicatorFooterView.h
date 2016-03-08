//
//  ZNGMessagesTypingIndicatorFooterView.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  A constant defining the default height of a `ZNGMessagesTypingIndicatorFooterView`.
 */
FOUNDATION_EXPORT const CGFloat kZNGMessagesTypingIndicatorFooterViewHeight;

/**
 *  The `ZNGMessagesTypingIndicatorFooterView` class implements a reusable view that can be placed
 *  at the bottom of a `ZNGMessagesCollectionView`. This view represents a typing indicator 
 *  for incoming messages.
 */
@interface ZNGMessagesTypingIndicatorFooterView : UICollectionReusableView

#pragma mark - Class methods

/**
 *  Returns the `UINib` object initialized for the collection reusable view.
 *
 *  @return The initialized `UINib` object or `nil` if there were errors during
 *  initialization or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 *  Returns the default string used to identify the reusable footer view.
 *
 *  @return The string used to identify the reusable footer view.
 */
+ (NSString *)footerReuseIdentifier;

#pragma mark - Typing indicator

/**
 *  Configures the receiver with the specified attributes for the given collection view. 
 *  Call this method after dequeuing the footer view.
 *
 *  @param ellipsisColor       The color of the typing indicator ellipsis. This value must not be `nil`.
 *  @param messageBubbleColor  The color of the typing indicator message bubble. This value must not be `nil`.
 *  @param shouldDisplayOnLeft Specifies whether the typing indicator displays on the left or right side of the collection view when displayed.
 *  @param collectionView      The collection view in which the footer view will appear. This value must not be `nil`.
 */
- (void)configureWithEllipsisColor:(UIColor *)ellipsisColor
                messageBubbleColor:(UIColor *)messageBubbleColor
               shouldDisplayOnLeft:(BOOL)shouldDisplayOnLeft
                 forCollectionView:(UICollectionView *)collectionView;

@end
