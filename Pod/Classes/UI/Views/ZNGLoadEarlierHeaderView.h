//
//  ZNGLoadEarlierHeaderView.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <UIKit/UIKit.h>

@class ZNGLoadEarlierHeaderView;

/**
 *  A constant defining the default height of a `ZNGLoadEarlierHeaderView`.
 */
FOUNDATION_EXPORT const CGFloat kZNGLoadEarlierHeaderViewHeight;

/**
 *  The `ZNGLoadEarlierHeaderViewDelegate` defines methods that allow you to
 *  respond to interactions within the header view.
 */
@protocol ZNGLoadEarlierHeaderViewDelegate <NSObject>

@required

/**
 *  Tells the delegate that the loadButton has received a touch event.
 *
 *  @param headerView The header view that contains the sender.
 *  @param sender     The button that received the touch.
 */
- (void)headerView:(ZNGLoadEarlierHeaderView *)headerView didPressLoadButton:(UIButton *)sender;

@end


/**
 *  The `ZNGLoadEarlierHeaderView` class implements a reusable view that can be placed
 *  at the top of a `ZNGCollectionView`. This view contains a "load earlier messages" button
 *  and can be used as a way for the user to load previously sent messages.
 */
@interface ZNGLoadEarlierHeaderView : UICollectionReusableView

/**
 *  The object that acts as the delegate of the header view.
 */
@property (weak, nonatomic) id<ZNGLoadEarlierHeaderViewDelegate> delegate;

/**
 *  Returns the load button of the header view.
 */
@property (weak, nonatomic, readonly) UIButton *loadButton;

#pragma mark - Class methods

/**
 *  Returns the `UINib` object initialized for the collection reusable view.
 *
 *  @return The initialized `UINib` object or `nil` if there were errors during
 *  initialization or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 *  Returns the default string used to identify the reusable header view.
 *
 *  @return The string used to identify the reusable header view.
 */
+ (NSString *)headerReuseIdentifier;

@end
