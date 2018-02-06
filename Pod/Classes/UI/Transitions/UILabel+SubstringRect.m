//
//  UILabel+SubstringRect.m
//  ZingleSDK
//
//  Created by Jason Neel on 2/6/18.
//

#import "UILabel+SubstringRect.h"

@implementation UILabel (SubstringRect)

- (CGRect) boundingRectForTextRange:(NSRange)range
{
    // Protect bounds
    if ((range.location + range.length) >= [self.attributedText length]) {
        return CGRectZero;
    }
    
    // I really wish we could access the UILabel's internal layout manager :(
    NSTextStorage * textStorage = [[NSTextStorage alloc] initWithAttributedString:[self attributedText]];
    NSLayoutManager * layoutManager = [[NSLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    
    NSTextContainer * textContainer = [[NSTextContainer alloc] initWithSize:self.bounds.size];
    textContainer.lineFragmentPadding = 0.0;
    [layoutManager addTextContainer:textContainer];
    
    NSRange glyphRange;
    [layoutManager characterRangeForGlyphRange:range actualGlyphRange:&glyphRange];
    
    return [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
}


- (CGRect) boundingRectForFirstLine
{
    NSRange firstLineFeedRange = [self.text rangeOfString:@"\n"];
    
    if (firstLineFeedRange.location == NSNotFound) {
        return CGRectZero;
    }
    
    return [self boundingRectForTextRange:NSMakeRange(0, firstLineFeedRange.location)];
}

@end
