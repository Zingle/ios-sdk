//
//  ZNGMessagesInputToolbar.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "ZNGMessagesToolbarContentView.h"

@class ZNGMessagesInputToolbar;


/**
 *  The `ZNGMessagesInputToolbarDelegate` protocol defines methods for interacting with
 *  a `ZNGMessagesInputToolbar` object.
 */
@protocol ZNGMessagesInputToolbarDelegate <UIToolbarDelegate>

@required

/**
 *  Tells the delegate that the toolbar's `rightBarButtonItem` has been pressed.
 *
 *  @param toolbar The object representing the toolbar sending this information.
 *  @param sender  The button that received the touch event.
 */
- (void)messagesInputToolbar:(ZNGMessagesInputToolbar *)toolbar
      didPressRightBarButton:(UIButton *)sender;

/**
 *  Tells the delegate that the toolbar's `leftBarButtonItem` has been pressed.
 *
 *  @param toolbar The object representing the toolbar sending this information.
 *  @param sender  The button that received the touch event.
 */
- (void)messagesInputToolbar:(ZNGMessagesInputToolbar *)toolbar
       didPressLeftBarButton:(UIButton *)sender;

@end


/**
 *  An instance of `ZNGMessagesInputToolbar` defines the input toolbar for
 *  composing a new message. It is displayed above and follow the movement of the system keyboard.
 */
@interface ZNGMessagesInputToolbar : UIToolbar

/**
 *  The object that acts as the delegate of the toolbar.
 */
@property (weak, nonatomic) id<ZNGMessagesInputToolbarDelegate> delegate;

/**
 *  Returns the content view of the toolbar. This view contains all subviews of the toolbar.
 */
@property (weak, nonatomic, readonly) ZNGMessagesToolbarContentView *contentView;

/**
 *  A boolean value indicating whether the send button is on the right side of the toolbar or not.
 *
 *  @discussion The default value is `YES`, which indicates that the send button is the right-most subview of
 *  the toolbar's `contentView`. Set to `NO` to specify that the send button is on the left. This
 *  property is used to determine which touch events correspond to which actions.
 *
 *  @warning Note, this property *does not* change the positions of buttons in the toolbar's content view.
 *  It only specifies whether the `rightBarButtonItem `or the `leftBarButtonItem` is the send button.
 *  The other button then acts as the accessory button.
 */
@property (assign, nonatomic) BOOL sendButtonOnRight;

/**
 *  Specifies the default (minimum) height for the toolbar. The default value is `44.0f`. This value must be positive.
 */
@property (assign, nonatomic) CGFloat preferredDefaultHeight;

/**
 *  Specifies the maximum height for the toolbar. The default value is `NSNotFound`, which specifies no maximum height.
 */
@property (assign, nonatomic) NSUInteger maximumHeight;

/**
 *  Enables or disables the send button based on whether or not its `textView` has text.
 *  That is, the send button will be enabled if there is text in the `textView`, and disabled otherwise.
 */
- (void)toggleSendButtonEnabled;

/**
 *  Loads the content view for the toolbar.
 *
 *  @discussion Override this method to provide a custom content view for the toolbar.
 *
 *  @return An initialized `ZNGMessagesToolbarContentView` if successful, otherwise `nil`.
 */
- (ZNGMessagesToolbarContentView *)loadToolbarContentView;

@end
