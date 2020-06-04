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
    
    [self.attributedText enumerateAttributesInRange:NSMakeRange(0, [self.attributedText length]) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        if (![[attrs allKeys] containsObject:ZNGEventMentionAttribute]) {
            return;
        }
        
        NSArray<NSValue *> * rects = [self rectsForTextInRange:range];
        
        for (NSValue * rectValue in rects) {
            CGRect rect = [rectValue CGRectValue];
            
            // Pad a bit to the left
            rect.origin.x -= self.highlightPadding;
            rect.size.width += self.highlightPadding;
            
            UIView * mentionHighlight = [[UIView alloc] initWithFrame:rect];
            mentionHighlight.backgroundColor = self.mentionHighlightColor;
            mentionHighlight.layer.cornerRadius = self.mentionHighlightCornerRadius;
            [newMentionHighlights addObject:mentionHighlight];
            [self insertSubview:mentionHighlight atIndex:0];
        }
    }];

    mentionHighlights = newMentionHighlights;
}

- (NSArray<NSValue *> *) rectsForTextInRange:(NSRange)range
{
    NSString * substring = [[self.attributedText attributedSubstringFromRange:range] string];
    NSArray<NSString *> * components = [substring componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableArray<NSValue *> * componentRects = [[NSMutableArray alloc] initWithCapacity:[components count]];
    NSUInteger currentLocation = 0;
    
    for (NSString * component in components) {
        NSRange searchRange = NSMakeRange(currentLocation, [substring length] - currentLocation);
        NSRange localRange = [substring rangeOfString:component options:0 range:searchRange];
        
        if (localRange.location == NSNotFound) {
            SBLogError(@"Something has gone horribly wrong when calculating mention string ranges.");
            return @[];
        }
        
        // The range of this component within the entire `self.attributedText`.
        // This could be slightly simplified with more trust and understanding in exactly how UITextPosition is
        //  calculated relatively, (probably eliminating the need for this first conversion to `globalRange`).
        NSRange globalRange = NSMakeRange(range.location + localRange.location, localRange.length);
        UITextPosition * beginning = self.beginningOfDocument;
        UITextPosition * start = [self positionFromPosition:beginning offset:globalRange.location];
        UITextPosition * end = [self positionFromPosition:start offset:globalRange.length];
        UITextRange * textRange = [self textRangeFromPosition:start toPosition:end];
        
        CGRect rect = [self firstRectForRange:textRange];
        [componentRects addObject:[NSValue valueWithCGRect:rect]];
        currentLocation += localRange.length;
    }
    
    // We now have individual rects for each word in the mention. We now need to detect rects that occur on the same
    //  line and combine those.
    NSMutableArray<NSValue *> * joinedRects = [[NSMutableArray alloc] initWithCapacity:[componentRects count]];
    
    for (NSValue * rectValue in componentRects) {
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
    // Strict comparison of X value may be good enough.  I'm not sure if descenders will break this.
    return (rect1.origin.y == rect2.origin.y);
}

@end
