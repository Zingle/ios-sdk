//
//  ZNGMessageTableViewCell.h
//  Pods
//
//  Created by Ryan Farley on 3/2/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGArrowView.h"

@class ZNGMessageViewModel;

@interface ZNGMessageTableViewCell : UITableViewCell

typedef NS_ENUM(NSInteger, ZNGArrowPosition) {
    ZNGArrowPositionUnset,
    ZNGArrowPositionBottom,
    ZNGArrowPositionTop,
    ZNGArrowPositionSide
};

+ (NSString *)reuseIdentifier;

- (void) configureCellForMessage:(ZNGMessageViewModel *)messageViewModel withDirection:(NSString *)direction;

@end
