//
//  UITextView+TextRects.h
//  ZingleSDK
//
//  Created by Jason Neel on 6/11/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITextView (TextRects)

/**
* One of more `CGRect ``NSValue`s that visually contain the specified range.  There will be more than one if this text is wrapped.
*/
- (NSArray<NSValue *> *) rectsForTextInRange:(NSRange)textRange withExtraPadding:(CGFloat)padding;

/**
* One of more `CGRect ``NSValue`s that visually contain the specified range.  There will be more than one if this text is wrapped.
 * This uses the default padding of 3.0.  Use `rectsForTextInRange:withExtraPadding:` to specify different or no padding.
*/
- (NSArray<NSValue *> *) rectsForTextInRange:(NSRange)textRange;

@end

NS_ASSUME_NONNULL_END
