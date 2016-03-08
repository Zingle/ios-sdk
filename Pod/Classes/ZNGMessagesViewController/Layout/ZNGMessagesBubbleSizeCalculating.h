//
//  ZNGMessagesBubbleSizeCalculating.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ZNGMessagesCollectionViewFlowLayout;
@protocol ZNGMessageData;

/**
 *  The `ZNGMessagesBubbleSizeCalculating` protocol defines the common interface through which
 *  an object provides layout information to an instance of `ZNGMessagesCollectionViewFlowLayout`.
 *
 *  A concrete class that conforms to this protocol is provided in the library.
 *  See `ZNGMessagesBubbleSizeCalculator`.
 */
@protocol ZNGMessagesBubbleSizeCalculating <NSObject>

/**
 *  Computes and returns the size of the `messageBubbleImageView` property 
 *  of a `ZNGMessagesCollectionViewCell` for the specified messageData at indexPath.
 *
 *  @param messageData A message data object.
 *  @param indexPath   The index path at which messageData is located.
 *  @param layout      The layout object asking for this information.
 *
 *  @return A sizes that specifies the required dimensions to display the entire message contents.
 *  Note, this is *not* the entire cell, but only its message bubble.
 */
- (CGSize)messageBubbleSizeForMessageData:(id<ZNGMessageData>)messageData
                              atIndexPath:(NSIndexPath *)indexPath
                               withLayout:(ZNGMessagesCollectionViewFlowLayout *)layout;

/**
 *  Notifies the receiver that the layout will be reset. 
 *  Use this method to clear any cached layout information, if necessary.
 *
 *  @param layout The layout object notifying the receiver.
 */
- (void)prepareForResettingLayout:(ZNGMessagesCollectionViewFlowLayout *)layout;

@end
