//
//  ZNGConversationTypingIndicatorCell.h
//  Pods
//
//  Created by Jason Neel on 8/31/17.
//
//

#import <JSQMessagesViewController/JSQMessagesCollectionViewCellOutgoing.h>

@interface ZNGConversationTypingIndicatorCell : JSQMessagesCollectionViewCellOutgoing

@property (nonatomic, strong, nullable) IBOutlet UIView * bouncingCircleContainerView;

/**
 *  Color of the bouncing dots.  Defaults to white.
 */
@property (nonatomic, strong, nonnull) UIColor * dotColor;

/**
 *  The ideal size of the entire typing indicator bubble.
 */
+ (CGSize) size;

@end
