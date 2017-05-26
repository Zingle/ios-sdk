//
//  ZNGEventViewModel.h
//  Pods
//
//  Created by Jason Neel on 1/13/17.
//
//  This class is used to separate separate rendered items in a single ZNGEvent into pieces that can be individually processed by UI code.
//
//

#import <Foundation/Foundation.h>
#import "JSQMessagesViewController/JSQMessageData.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  An NSNotification will be posted to the shared NSNotificationCenter with this name and the ZNGEventViewModel as its object if
 *   the image size corresponding to this event view model has changed (i.e. it was not loaded/cached, and now we know how big it is.)
 */
extern NSString * const ZNGEventViewModelImageSizeChangedNotification;

@class ZNGEvent;

@interface ZNGEventViewModel : NSObject <JSQMessageData, JSQMessageMediaData>

/**
 *  The index of this view model within the originiating event.
 */
@property (nonatomic, assign) NSUInteger index;

@property (nonatomic, strong) ZNGEvent * event;

/**
 *  The name/URL string of the attachment represented by this ZNGEventViewModel.  nil if this is a text entry.
 */
@property (nonatomic, readonly) NSString * attachmentName;

/**
 *  Flag that is set if we are confidence that our mediaViewDisplaySize is accurate and not an estimate.
 */
@property (nonatomic, readonly) BOOL exactImageSizeCalculated;

- (id) initWithEvent:(ZNGEvent *)event index:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
