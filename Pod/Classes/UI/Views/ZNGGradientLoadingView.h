//
//  ZNGGradientLoadingView.h
//  Pods
//
//  Created by Jason Neel on 9/28/16.
//
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface ZNGGradientLoadingView : UIView

@property (nonatomic, assign) IBInspectable BOOL hidesWhenStopped;
@property (nonatomic, strong) IBInspectable UIColor * centerColor;
@property (nonatomic, strong) IBInspectable UIColor * edgeColor;

- (void) startAnimating;
- (void) stopAnimating;

@end
