//
//  UITextView+TextRects.m
//  ZingleSDK
//
//  Created by Jason Neel on 6/11/20.
//

#import "UITextView+TextRects.h"

@import SBObjectiveCWrapper;

static const CGFloat DefaultPadding = 3.0;

@implementation UITextView (TextRects)

- (NSArray<NSValue *> *) rectsForTextInRange:(NSRange)textRange
{
    return [self rectsForTextInRange:textRange withExtraPadding:DefaultPadding];
}

- (NSArray<NSValue *> *) rectsForTextInRange:(NSRange)textRange withExtraPadding:(CGFloat)padding
{
    UITextPosition * beginningOfMention = [self positionFromPosition:self.beginningOfDocument offset:textRange.location];
    
    // The string defined by our provided range
    NSString * mentionText = [[self.attributedText attributedSubstringFromRange:textRange] string];
    
    // The string split by whitespace into its non-whitespace components (read: words)
    NSArray<NSString *> * words = [mentionText componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // This array will include one rect for each word in this mention
    NSMutableArray<NSValue *> * wordRects = [[NSMutableArray alloc] initWithCapacity:[words count]];
    NSUInteger currentLocation = 0;
    
    // Loop through each word of the string within our range, calculating the individual rects surrounding each word
    //  to be later joined.
    for (NSString * word in words) {
        // The remaining range of mentionText, shrinking forward as we calculate rects for words
        NSRange searchRange = NSMakeRange(currentLocation, [mentionText length] - currentLocation);
        
        // The range of this word within our mentionText
        NSRange wordRange = [mentionText rangeOfString:word options:0 range:searchRange];
        
        if (wordRange.location == NSNotFound) {
            SBLogError(@"Something has gone horribly wrong when calculating mention string ranges.");
            return @[];
        }

        UITextPosition * wordStart = [self positionFromPosition:beginningOfMention offset:wordRange.location];
        UITextPosition * wordEnd = [self positionFromPosition:wordStart offset:wordRange.length];
        UITextRange * textRange = [self textRangeFromPosition:wordStart toPosition:wordEnd];
        
        CGRect rect = [self firstRectForRange:textRange];
        [wordRects addObject:[NSValue valueWithCGRect:rect]];
        
        currentLocation = wordRange.location + wordRange.length;
    }
    
    // We have individual rects for each word in the mention.
    // We now need to detect multiple rects that occur on the same line and combine those.
    NSMutableArray<NSValue *> * joinedRects = [[NSMutableArray alloc] initWithCapacity:[words count]];
    
    for (NSValue * rectValue in wordRects) {
        CGRect thisRect = [rectValue CGRectValue];
        NSValue * previousRect = [joinedRects lastObject];
        
        if ((previousRect != nil) && ([self rectsCoexistOnSingleLine:thisRect secondRect:[previousRect CGRectValue]])) {
            // Join the two rects
            [joinedRects removeLastObject];
            [joinedRects addObject:[NSValue valueWithCGRect:CGRectUnion([previousRect CGRectValue], thisRect)]];
        } else {
            [joinedRects addObject:[NSValue valueWithCGRect:thisRect]];
        }
    }
    
    // Apply padding
    if (padding != 0.0) {
        NSMutableArray<NSValue *> * paddedRects = [[NSMutableArray alloc] initWithCapacity:[joinedRects count]];
        
        [joinedRects enumerateObjectsUsingBlock:^(NSValue * _Nonnull rectValue, NSUInteger i, BOOL * _Nonnull stop) {
            CGRect rect = [rectValue CGRectValue];
            
            // Pad a bit to the left
            rect.origin.x -= padding;
            rect.size.width += padding;
            
            // A bit of right padding is also needed if...
            //  1) This is a non-terminal part of a split mention
            BOOL nonTerminalWrapped = (([joinedRects count] > 1) && (i < ([joinedRects count] - 1)));
            //  or 2) This is the very last word of the entire message
            BOOL wordEndsMention = (i == ([joinedRects count] - 1));
            BOOL mentionEndsMessage = ((textRange.location + textRange.length) == [self.attributedText length]);
            BOOL wordEndsMessage = (wordEndsMention && mentionEndsMessage);
                                        
            if (nonTerminalWrapped || wordEndsMessage) {
                rect.size.width += padding;
            }
            
            [paddedRects addObject:[NSValue valueWithCGRect:rect]];
        }];
    
        joinedRects = paddedRects;
    }

    return joinedRects;
}

- (BOOL) rectsCoexistOnSingleLine:(CGRect)rect1 secondRect:(CGRect)rect2
{
    // A strict equivalency check of Y is probably good enough, but we'll be safe and
    //  add some wiggle room equal to half rect1's height
    CGFloat margin = rect1.size.height / 2.0;
    CGFloat diff = fabs(rect1.origin.y - rect2.origin.y);
    return (diff < margin);
}

@end
