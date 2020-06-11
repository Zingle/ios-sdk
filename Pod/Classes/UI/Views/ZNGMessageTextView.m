//
//  ZNGMessageTextView.m
//  ZingleSDK
//
//  Created by Jason Neel on 6/3/20.
//

#import "ZNGMessageTextView.h"
#import "ZNGEventViewModel.h"
#import "UITextView+TextRects.h"

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

@end
