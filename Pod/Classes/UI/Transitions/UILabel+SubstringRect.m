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
    
    NSMutableAttributedString * attributedString = [[self attributedText] mutableCopy];
    
    // Does our attributed string have a font attribute?  If not, we'll want to add our own.
    __block BOOL foundFontAttribute = NO;
    [attributedString enumerateAttributesInRange:range options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        if (attrs[NSFontAttributeName] != nil) {
            foundFontAttribute = YES;
            *stop = YES;
        }
    }];
    
    if (!foundFontAttribute) {
        [attributedString addAttribute:NSFontAttributeName value:self.font range:range];
    }
    
    // If our alignment is not lefty, attribute that jazz
    if (self.textAlignment != NSTextAlignmentLeft) {
        NSMutableParagraphStyle * style = [[NSMutableParagraphStyle alloc] init];
        style.alignment = self.textAlignment;
        [attributedString addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, [attributedString length])];
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
    
    if (firstLineFeedRange.location == NSNotFound) {
        return CGRectZero;
    }
    
    return [self boundingRectForTextRange:NSMakeRange(0, firstLineFeedRange.location)];
}

@end
