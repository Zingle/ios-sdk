//
//  ZNGMessagesMediaViewBubbleImageMasker.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ZNGMessagesBubbleImageFactory;

/**
 *  An instance of `ZNGMessagesMediaViewBubbleImageMasker` is an object that masks
 *  media views for a `ZNGMessageMediaData` object. Given a view, it will mask the view
 *  with a bubble image for an outgoing or incoming media view.
 *
 *  @see ZNGMessageMediaData.
 *  @see ZNGMessagesBubbleImageFactory.
 *  @see ZNGMessagesBubbleImage.
 */
@interface ZNGMessagesMediaViewBubbleImageMasker : NSObject

/**
 *  Returns the bubble image factory that the masker uses to mask media views.
 */
@property (strong, nonatomic, readonly) ZNGMessagesBubbleImageFactory *bubbleImageFactory;

/**
 *  Creates and returns a new instance of `ZNGMessagesMediaViewBubbleImageMasker`
 *  that uses a default instance of `ZNGMessagesBubbleImageFactory`. The masker uses the `ZNGMessagesBubbleImage`
 *  objects returned by the factory to mask media views.
 *
 *  @return An initialized `ZNGMessagesMediaViewBubbleImageMasker` object if created successfully, `nil` otherwise.
 *
 *  @see ZNGMessagesBubbleImageFactory.
 *  @see ZNGMessagesBubbleImage.
 */
- (instancetype)init;

/**
 *  Creates and returns a new instance of `ZNGMessagesMediaViewBubbleImageMasker`
 *  having the specified bubbleImageFactory. The masker uses the `ZNGMessagesBubbleImage`
 *  objects returned by the factory to mask media views.
 *
 *  @param bubbleImageFactory An initialized `ZNGMessagesBubbleImageFactory` object to use for masking media views. This value must not be `nil`.
 *
 *  @return An initialized `ZNGMessagesMediaViewBubbleImageMasker` object if created successfully, `nil` otherwise.
 *
 *  @see ZNGMessagesBubbleImageFactory.
 *  @see ZNGMessagesBubbleImage.
 */
- (instancetype)initWithBubbleImageFactory:(ZNGMessagesBubbleImageFactory *)bubbleImageFactory;

/**
 *  Applies an outgoing bubble image mask to the specified mediaView.
 *
 *  @param mediaView The media view to mask.
 */
- (void)applyOutgoingBubbleImageMaskToMediaView:(UIView *)mediaView;

/**
 *  Applies an incoming bubble image mask to the specified mediaView.
 *
 *  @param mediaView The media view to mask.
 */
- (void)applyIncomingBubbleImageMaskToMediaView:(UIView *)mediaView;

/**
 *  A convenience method for applying a bubble image mask to the specified mediaView.
 *  This method uses the default instance of `ZNGMessagesBubbleImageFactory`.
 *
 *  @param mediaView  The media view to mask.
 *  @param isOutgoing A boolean value specifiying whether or not the mask should be for an outgoing or incoming view.
 *  Specify `YES` for outgoing and `NO` for incoming.
 */
+ (void)applyBubbleImageMaskToMediaView:(UIView *)mediaView isOutgoing:(BOOL)isOutgoing;

@end
