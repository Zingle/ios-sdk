//
//  ZNGMessageTextView.m
//  ZingleSDK
//
//  Created by Jason Neel on 6/3/20.
//

#import "ZNGMessageTextView.h"
#import "ZNGEventViewModel.h"

@import SBObjectiveCWrapper;

@implementation ZNGMessageTextView
{
    NSArray<UIView *> * mentionHighlights;
}

- (id) initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (id) initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
    self = [super initWithFrame:frame textContainer:textContainer];
    
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (void) commonInit
{
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGMessageTextView class]];
    _mentionHighlightColor = [UIColor colorNamed:@"ZNGInternalNoteHighlightedBackground" inBundle:bundle compatibleWithTraitCollection:nil];
    _mentionHighlightCornerRadius = 3.0;
    _highlightPadding = 3.0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyTextChanged:) name:UITextViewTextDidChangeNotification object:nil];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) setMentionHighlightColor:(UIColor *)mentionHighlightColor
{
    _mentionHighlightColor = mentionHighlightColor;
    [self updateHighlights];
}

- (void) setMentionHighlightCornerRadius:(CGFloat)mentionHighlightCornerRadius
{
    _mentionHighlightCornerRadius = mentionHighlightCornerRadius;
    [self updateHighlights];
}

- (void) setHighlightPadding:(CGFloat)highlightPadding
{
    _highlightPadding = highlightPadding;
    [self updateHighlights];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    [self updateHighlights];
}

- (void) notifyTextChanged:(NSNotification *)notification
{
    [self updateHighlights];
}

- (void) updateHighlights
{
    for (UIView * mentionView in mentionHighlights) {
        [mentionView removeFromSuperview];
    }
    
    __block NSMutableArray<UIView *> * newMentionHighlights = [[NSMutableArray alloc] init];
    
    // Enumerate through all attributes in our text, searching for @mention attributes
    [self.attributedText enumerateAttributesInRange:NSMakeRange(0, [self.attributedText length]) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        if (![[attrs allKeys] containsObject:ZNGEventMentionAttribute]) {
            // This block of attribute(s) did not contain a mention
            return;
        }
        
        // We have a mention.  Let's calculate the rect(s) that contain it and add highlighter background views.
        
        NSArray<NSValue *> * rects = [self rectsForTextInRange:range];
        
        [rects enumerateObjectsUsingBlock:^(NSValue * _Nonnull rectValue, NSUInteger i, BOOL * _Nonnull stop) {
            CGRect rect = [rectValue CGRectValue];
            
            // Pad a bit to the left
            rect.origin.x -= self.highlightPadding;
            rect.size.width += self.highlightPadding;
            
            // A bit of right padding is also needed if...
            //  1) This is a non-terminal part of a split mention
            BOOL nonTerminalWrapped = (([rects count] > 1) && (i < ([rects count] - 1)));
            //  2) This is the very last word of the entire message
            BOOL wordEndsMention = (i == ([rects count] - 1));
            BOOL mentionEndsMessage = ((range.location + range.length) == [self.attributedText length]);
            BOOL wordEndsMessage = (wordEndsMention && mentionEndsMessage);
                                        
            if (nonTerminalWrapped || wordEndsMessage) {
                rect.size.width += self.highlightPadding;
            }
            
            UIView * mentionHighlight = [[UIView alloc] initWithFrame:rect];
            mentionHighlight.backgroundColor = self.mentionHighlightColor;
            mentionHighlight.layer.cornerRadius = self.mentionHighlightCornerRadius;
            [newMentionHighlights addObject:mentionHighlight];
            [self insertSubview:mentionHighlight atIndex:0];
        }];

    }];

    mentionHighlights = newMentionHighlights;
}

/**
 * One of more CGRects that visually contain the specified range.  There will be more than one if this text is wrapped.
 */
- (NSArray<NSValue *> *) rectsForTextInRange:(NSRange)mentionRange
{
    UITextPosition * beginningOfMention = [self positionFromPosition:self.beginningOfDocument offset:mentionRange.location];
    
    // The string defined by our provided range
    NSString * mentionText = [[self.attributedText attributedSubstringFromRange:mentionRange] string];
    
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
