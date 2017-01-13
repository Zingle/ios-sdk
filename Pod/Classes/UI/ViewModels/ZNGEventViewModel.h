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

NS_ASSUME_NONNULL_BEGIN

@class ZNGEvent;

@interface ZNGEventViewModel : NSObject

/**
 *  The index of this view model within the originiating event.
 */
@property (nonatomic, assign) NSUInteger index;

@property (nonatomic, strong) ZNGEvent * event;

- (id) initWithEvent:(ZNGEvent *)event index:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
