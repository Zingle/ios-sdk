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
- (NSRange) rangeOfFirstLine;


/**
 *  Returns the size of a provided substring.  If there is more than one size in the substring, the size of the
 *   first character will be returned.
 */
- (CGFloat) fontSizeOfSubstring:(NSString *)substring;

@end
