//
//  ZNGMessagesCollectionView.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <UIKit/UIKit.h>

#import "ZNGMessagesCollectionViewFlowLayout.h"
#import "ZNGMessagesCollectionViewDelegateFlowLayout.h"
#import "ZNGMessagesCollectionViewDataSource.h"
#import "ZNGMessagesCollectionViewCell.h"

@class ZNGMessagesTypingIndicatorFooterView;
@class ZNGMessagesLoadEarlierHeaderView;


/**
 *  The `ZNGMessagesCollectionView` class manages an ordered collection of message data items and presents
 *  them using a specialized layout for messages.
 */
@interface ZNGMessagesCollectionView : UICollectionView <ZNGMessagesCollectionViewCellDelegate>

/**
 *  The object that provides the data for the collection view.
 *  The data source must adopt the `ZNGMessagesCollectionViewDataSource` protocol.
 */
@property (weak, nonatomic) id<ZNGMessagesCollectionViewDataSource> dataSource;

/**
 *  The object that acts as the delegate of the collection view. 
 *  The delegate must adopt the `ZNGMessagesCollectionViewDelegateFlowLayout` protocol.
 */
@property (weak, nonatomic) id<ZNGMessagesCollectionViewDelegateFlowLayout> delegate;

/**
 *  The layout used to organize the collection view’s items.
 */
@property (strong, nonatomic) ZNGMessagesCollectionViewFlowLayout *collectionViewLayout;

/**
 *  Specifies whether the typing indicator displays on the left or right side of the collection view
 *  when shown. That is, whether it displays for an "incoming" or "outgoing" message.
 *  The default value is `YES`, meaning that the typing indicator will display on the left side of the
 *  collection view for incoming messages.
 *
 *  @discussion If your `ZNGMessagesViewController` subclass displays messages for right-to-left
 *  languages, such as Arabic, set this property to `NO`.
 *
 */
@property (assign, nonatomic) BOOL typingIndicatorDisplaysOnLeft;

/**
 *  The color of the typing indicator message bubble. The default value is a light gray color.
 */
@property (strong, nonatomic) UIColor *typingIndicatorMessageBubbleColor;

/**
 *  The color of the typing indicator ellipsis. The default value is a dark gray color.
 */
@property (strong, nonatomic) UIColor *typingIndicatorEllipsisColor;

/**
 *  The color of the text in the load earlier messages header. The default value is a bright blue color.
 */
@property (strong, nonatomic) UIColor *loadEarlierMessagesHeaderTextColor;

/**
 *  Returns a `ZNGMessagesTypingIndicatorFooterView` object for the specified index path
 *  that is configured using the collection view's properties:
 *  typingIndicatorDisplaysOnLeft, typingIndicatorMessageBubbleColor, typingIndicatorEllipsisColor.
 *
 *  @param indexPath The index path specifying the location of the supplementary view in the collection view. This value must not be `nil`.
 *
 *  @return A valid `ZNGMessagesTypingIndicatorFooterView` object.
 */
- (ZNGMessagesTypingIndicatorFooterView *)dequeueTypingIndicatorFooterViewForIndexPath:(NSIndexPath *)indexPath;

/**
 *  Returns a `ZNGMessagesLoadEarlierHeaderView` object for the specified index path
 *  that is configured using the collection view's loadEarlierMessagesHeaderTextColor property.
 *
 *  @param indexPath The index path specifying the location of the supplementary view in the collection view. This value must not be `nil`.
 *
 *  @return A valid `ZNGMessagesLoadEarlierHeaderView` object.
 */
- (ZNGMessagesLoadEarlierHeaderView *)dequeueLoadEarlierMessagesViewHeaderForIndexPath:(NSIndexPath *)indexPath;

@end
