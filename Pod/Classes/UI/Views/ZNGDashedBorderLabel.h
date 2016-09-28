//
//  ZNGDashedBorderLabel.h
//  Pods
//
//  Created by Jason Neel on 9/28/16.
//
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface ZNGDashedBorderLabel : UILabel

@property (nonatomic, copy, nullable) IBInspectable UIColor * borderColor;
@property (nonatomic, assign) IBInspectable CGFloat borderWidth;
@property (nonatomic, assign) IBInspectable CGFloat textInset;
@property (nonatomic, assign) IBInspectable BOOL dashed;
@property (nonatomic, assign) IBInspectable CGFloat cornerRadius;

@end
