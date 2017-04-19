//
//  UILabel+NetworkStatus.h
//  Pods
//
//  Created by Jason Neel on 4/18/17.
//
//

#import <UIKit/UIKit.h>
#import "ZNGNetworkLookout.h"

@interface UILabel (NetworkStatus)

- (void) updateWithNetworkStatus:(ZNGNetworkLookoutStatus)status;

@end
