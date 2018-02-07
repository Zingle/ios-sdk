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
    if ((range.location + range.length) > [self.attributedText length]) {
        return CGRectZero;
    }
    
    NSMutableAttributedString * attributedString = [[self attributedText] mutableCopy];
    
    // This seems ugly and inefficient, but going character-by-character is the simplest way I could find to avoid
    //  problems of attribute overlap while applying default attributes for font and alignment.
    NSMutableParagraphStyle * style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = self.textAlignment;
    
    for (NSUInteger i = 0; i < [attributedString length]; i++) {
        NSDictionary * attributes = [attributedString attributesAtIndex:i effectiveRange:nil];
        NSRange thisRange = NSMakeRange(i, 1);
        
        if (attributes[NSFontAttributeName] == nil) {
            [attributedString addAttribute:NSFontAttributeName value:self.font range:thisRange];
        }
        
        if ((self.textAlignment != NSTextAlignmentLeft) && (attributes[NSParagraphStyleAttributeName] == nil)) {
            [attributedString addAttribute:NSParagraphStyleAttributeName value:style range:thisRange];
        }
    }
    
    // I really wish we could access the UILabel's internal layout manager :(
    NSTextStorage * textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedString];
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
    
    if (firstLineFeedRange.location != NSNotFound) {
        return [self boundingRectForTextRange:NSMakeRange(0, firstLineFeedRange.location)];
    }
    
    return [self boundingRectForTextRange:NSMakeRange(0, [self.text length])];
}

@end
