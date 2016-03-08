//
//  ZNGMessagesCollectionViewFlowLayoutInvalidationContext.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <UIKit/UIKit.h>

/**
 *  A `ZNGMessagesCollectionViewFlowLayoutInvalidationContext` object specifies properties for 
 *  determining whether to recompute the size of items or their position in the layout. 
 *  The flow layout object creates instances of this class when it needs to invalidate its contents 
 *  in response to changes. You can also create instances when invalidating the flow layout manually.
 *
 */
@interface ZNGMessagesCollectionViewFlowLayoutInvalidationContext : UICollectionViewFlowLayoutInvalidationContext

/**
 *  A boolean indicating whether to empty the messages layout information cache for items and views in the layout.
 *  The default value is `NO`.
 */
@property (nonatomic, assign) BOOL invalidateFlowLayoutMessagesCache;

/**
 *  Creates and returns a new `ZNGMessagesCollectionViewFlowLayoutInvalidationContext` object.
 *
 *  @discussion When you need to invalidate the `ZNGMessagesCollectionViewFlowLayout` object for your
 *  `ZNGMessagesViewController` subclass, you should use this method to instantiate a new invalidation 
 *  context and pass this object to `invalidateLayoutWithContext:`.
 *
 *  @return An initialized invalidation context object if successful, otherwise `nil`.
 */
+ (instancetype)context;

@end
