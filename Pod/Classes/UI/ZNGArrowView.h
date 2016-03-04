//
//  ZNGArrowView.h
//  ZingleSDK
//
//  Copyright © 2015 Zingle.me. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZNGArrowView : UIView

typedef NS_ENUM(NSInteger, ZNGArrowDirection) {
    ZNGArrowDirectionUp,
    ZNGArrowDirectionDown,
    ZNGArrowDirectionLeft,
    ZNGArrowDirectionRight
};

@property (nonatomic, retain) UIColor *color;
@property (nonatomic) ZNGArrowDirection direction;
@property (nonatomic) int bias;

@end
