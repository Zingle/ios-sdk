//
//  ZNGCollectionViewDataSource.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ZNGCollectionView;
@protocol ZNGMessageData;
@protocol ZNGMessageBubbleImageDataSource;
@protocol ZNGMessageAvatarImageDataSource;


/**
 *  An object that adopts the `ZNGCollectionViewDataSource` protocol is responsible for providing the data and views
 *  required by a `ZNGCollectionView`. The data source object represents your app’s messaging data model
 *  and vends information to the collection view as needed.
 */
@protocol ZNGCollectionViewDataSource <UICollectionViewDataSource>

@required

/**
 *  Asks the data source for the current sender's display name, that is, the current user who is sending messages.
 *
 *  @return An initialized string describing the current sender to display in a `ZNGCollectionViewCell`.
 *  
 *  @warning You must not return `nil` from this method. This value does not need to be unique.
 */
- (NSString *)senderDisplayName;

/**
 *  Asks the data source for the current sender's unique identifier, that is, the current user who is sending messages.
 *
 *  @return An initialized string identifier that uniquely identifies the current sender.
 *
 *  @warning You must not return `nil` from this method. This value must be unique.
 */
- (NSString *)senderId;

/**
 *  Asks the data source for the message data that corresponds to the specified item at indexPath in the collectionView.
 *
 *  @param collectionView The collection view requesting this information.
 *  @param indexPath      The index path that specifies the location of the item.
 *
 *  @return An initialized object that conforms to the `ZNGMessageData` protocol. You must not return `nil` from this method.
 */
- (id<ZNGMessageData>)collectionView:(ZNGCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Notifies the data source that the item at indexPath has been deleted. 
 *  Implementations of this method should remove the item from the data source.
 *
 *  @param collectionView The collection view requesting this information.
 *  @param indexPath      The index path that specifies the location of the item.
 */
- (void)collectionView:(ZNGCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Asks the data source for the message bubble image data that corresponds to the specified message data item at indexPath in the collectionView.
 *
 *  @param collectionView The collection view requesting this information.
 *  @param indexPath      The index path that specifies the location of the item.
 *
 *  @return An initialized object that conforms to the `ZNGMessageBubbleImageDataSource` protocol. You may return `nil` from this method if you do not
 *  want the specified item to display a message bubble image.
 *
 *  @discussion It is recommended that you utilize `ZNGBubbleImageFactory` to return valid `ZNGBubbleImage` objects.
 *  However, you may provide your own data source object as long as it conforms to the `ZNGMessageBubbleImageDataSource` protocol.
 *  
 *  @warning Note that providing your own bubble image data source objects may require additional 
 *  configuration of the collectionView layout object, specifically regarding its `messageBubbleTextViewFrameInsets` and `messageBubbleTextViewTextContainerInsets`.
 *
 *  @see ZNGBubbleImageFactory.
 *  @see ZNGCollectionViewFlowLayout.
 */
- (id<ZNGMessageBubbleImageDataSource>)collectionView:(ZNGCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Asks the data source for the avatar image data that corresponds to the specified message data item at indexPath in the collectionView.
 *
 *  @param collectionView The collection view requesting this information.
 *  @param indexPath      The index path that specifies the location of the item.
 *
 *  @return A initialized object that conforms to the `ZNGMessageAvatarImageDataSource` protocol. You may return `nil` from this method if you do not want
 *  the specified item to display an avatar.
 *
 *  @discussion It is recommended that you utilize `ZNGAvatarImageFactory` to return valid `ZNGAvatarImage` objects.
 *  However, you may provide your own data source object as long as it conforms to the `ZNGMessageAvatarImageDataSource` protocol.
 *
 *  @see ZNGAvatarImageFactory.
 *  @see ZNGCollectionViewFlowLayout.
 */
- (id<ZNGMessageAvatarImageDataSource>)collectionView:(ZNGCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional

/**
 *  Asks the data source for the text to display in the `cellTopLabel` for the specified
 *  message data item at indexPath in the collectionView.
 *
 *  @param collectionView The collection view requesting this information.
 *  @param indexPath      The index path that specifies the location of the item.
 *
 *  @return A configured attributed string or `nil` if you do not want text displayed for the item at indexPath.
 *  Return an attributed string with `nil` attributes to use the default attributes.
 *
 *  @see ZNGCollectionViewCell.
 */
- (NSAttributedString *)collectionView:(ZNGCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Asks the data source for the text to display in the `messageBubbleTopLabel` for the specified
 *  message data item at indexPath in the collectionView.
 *
 *  @param collectionView The collection view requesting this information.
 *  @param indexPath      The index path that specifies the location of the item.
 *
 *  @return A configured attributed string or `nil` if you do not want text displayed for the item at indexPath.
 *  Return an attributed string with `nil` attributes to use the default attributes.
 *
 *  @see ZNGCollectionViewCell.
 */
- (NSAttributedString *)collectionView:(ZNGCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Asks the data source for the text to display in the `cellBottomLabel` for the the specified
 *  message data item at indexPath in the collectionView.
 *
 *  @param collectionView The collection view requesting this information.
 *  @param indexPath      The index path that specifies the location of the item.
 *
 *  @return A configured attributed string or `nil` if you do not want text displayed for the item at indexPath.
 *  Return an attributed string with `nil` attributes to use the default attributes.
 *
 *  @see ZNGCollectionViewCell.
 */
- (NSAttributedString *)collectionView:(ZNGCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath;

@end
