//
//  UILabel+SubstringRect.h
//  ZingleSDK
//
//  Created by Jason Neel on 2/6/18.
//

#import <UIKit/UIKit.h>

@interface UILabel (SubstringRect)

- (CGRect) boundingRectForTextRange:(NSRange)range;
- (CGRect) boundingRectForFirstLine;

@end
