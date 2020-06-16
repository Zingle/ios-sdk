//
//  ZNGConversationTextView.m
//  Pods
//
//  Created by Jason Neel on 7/21/16.
//
//

#import "ZNGConversationTextView.h"
#import <objc/runtime.h>
#import "UITextView+TextRects.h"

@import SBObjectiveCWrapper;

// Private method to configure views because JSQ is a jerk
@interface JSQMessagesComposerTextView()
- (void)jsq_configureTextView;
@end

@implementation ZNGConversationTextView
{
    NSArray<UIView *> * highlightViews;
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
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGConversationTextView class]];
    self.attributeHighlightColor = [UIColor colorNamed:@"ZNGInternalNoteHighlightedBackground" inBundle:bundle compatibleWithTraitCollection:nil];
    self.attributeHighlightCornerRadius = 3.0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyTextChanged:) name:UITextViewTextDidChangeNotification object:self];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) notifyTextChanged:(NSNotification *)notification
{
    [self updateHighlights];
}

- (void) setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    [self updateHighlights];
}

- (void) setAttributeHighlightColor:(UIColor *)attributeHighlightColor
{
    _attributeHighlightColor = attributeHighlightColor;
    [self updateHighlights];
}

- (void) setAttributeNamesToHighlight:(NSArray<NSString *> *)attributeNamesToHighlight
{
    _attributeNamesToHighlight = attributeNamesToHighlight;
    [self updateHighlights];
}

- (void) setAttributeHighlightCornerRadius:(CGFloat)attributeHighlightCornerRadius
{
    _attributeHighlightCornerRadius = attributeHighlightCornerRadius;
    [self updateHighlights];
}

- (void) jsq_configureTextView
{
    [super jsq_configureTextView];
    
    // The super call breaks our colors.  Fix them for dark mode.
    if (@available(iOS 13.0, *)) {
        self.backgroundColor = [UIColor systemBackgroundColor];
        self.textColor = [UIColor labelColor];
    }

    self.layer.borderColor = [[UIColor clearColor] CGColor];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    // We need to update our highlights when laying out subviews, but NSTextStorage gets quite upset if we attempt to calculate coordinates
    //  while it has an edit in progress.  We will defer to the next run loop iteration if an edit is in progress.
    if (self.textStorage.editedRange.location == NSNotFound) {
        [self updateHighlights];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateHighlights];
        });
    }
}

- (void) updateHighlights
{
    for (UIView * highlightView in highlightViews) {
        [highlightView removeFromSuperview];
    }
    
    if (([self.attributeNamesToHighlight count] == 0) || (self.attributeHighlightColor == nil)) {
        return;
    }
    
    NSMutableArray<UIView *> * newHighlightViews = [[NSMutableArray alloc] init];
    NSSet * attributesToHighlightSet = [[NSSet alloc] initWithArray:self.attributeNamesToHighlight];
    
    [self.attributedText enumerateAttributesInRange:NSMakeRange(0, [self.attributedText length]) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        NSSet * theseAttributes = [[NSSet alloc] initWithArray:[attrs allKeys]];
        if (![theseAttributes intersectsSet:attributesToHighlightSet]) {
            return;
        }
        
        NSArray<NSValue *> * rectValues = [self rectsForTextInRange:range];
        
        for (NSValue * rectValue in rectValues) {
            UIView * highlight = [[UIView alloc] initWithFrame:[rectValue CGRectValue]];
            highlight.backgroundColor = self.attributeHighlightColor;
            highlight.layer.cornerRadius = self.attributeHighlightCornerRadius;
            [newHighlightViews addObject:highlight];
            [self insertSubview:highlight atIndex:0];
        }
    }];
    
    highlightViews = newHighlightViews;
}

- (NSDictionary *) placeholderAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.alignment = self.textAlignment;
    
    return @{ NSFontAttributeName : self.font,
              NSForegroundColorAttributeName : self.placeHolderTextColor,
              NSParagraphStyleAttributeName : paragraphStyle };
}

- (void) drawRect:(CGRect)rect
{
    // JSQMessagesComposerTextView has some bone-headed hard-coded placeholder drawing code in its drawRect.
    // We need to do some runtime witchcraft to call superclass.superclass's drawRect (UITextView) before drawing
    //  the placeholder ourselves without hard-coded nonsense.
    Class granny = [[self superclass] superclass];
    IMP drawGranny = class_getMethodImplementation(granny, _cmd);
    ((void(*)(id, SEL))drawGranny)(self, _cmd);
    
    if (([self.text length] == 0) && ([self.placeHolder length] > 0)) {
        CGFloat x = self.textContainer.lineFragmentPadding + self.textContainerInset.left;
        CGFloat y = self.textContainerInset.top;
        CGFloat width = self.bounds.size.width - x - self.textContainer.lineFragmentPadding - self.textContainerInset.right;
        CGFloat height = self.bounds.size.height - y - self.textContainerInset.bottom;
        CGRect rect = CGRectMake(x, y, width, height);
        
        [self.placeHolder drawInRect:rect withAttributes:[self placeholderAttributes]];
    }
}

- (void) setHideCursor:(BOOL)hideCursor
{
    _hideCursor = hideCursor;
    [self setNeedsDisplay];
}

- (CGRect) caretRectForPosition:(UITextPosition *)position
{
    if (self.hideCursor) {
        return CGRectZero;
    }
    
    return [super caretRectForPosition:position];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (!self.editable) {
        return NO;
    }
    
    BOOL canPerform = NO;
    
    if (action == NSSelectorFromString(@"replace:")) {
        canPerform = YES;
    } else if ([self.text length] == 0) {
        if (action == @selector(paste:)) {
            canPerform = YES;
        }
    } else  {
        NSRange range = self.selectedRange;
        if (range.length > 0) {
            if (action == @selector(cut:) || action == @selector(copy:) ||
                action == @selector(select:) || action == @selector(selectAll:) ||
                action == @selector(paste:)) {
                canPerform = YES;
            }
        } else {
            if ( action == @selector(select:) || action == @selector(selectAll:) ||
                action == @selector(paste:)) {
                canPerform = YES;
            }
        }
    }
    
    SBLogVerbose(@"Returning %@ for %@ %@", canPerform ? @"YES" : @"NO", NSStringFromSelector(_cmd), NSStringFromSelector(action));
    
    return canPerform;
}

@end
