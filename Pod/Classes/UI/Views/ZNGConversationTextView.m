//
//  ZNGConversationTextView.m
//  Pods
//
//  Created by Jason Neel on 7/21/16.
//
//

#import "ZNGConversationTextView.h"
#import "ZNGLogging.h"
#import <objc/runtime.h>

static const int zngLogLevel = ZNGLogLevelWarning;

// Private method to configure views because JSQ is a jerk
@interface JSQMessagesComposerTextView()
- (void)jsq_configureTextView;
@end

@implementation ZNGConversationTextView

- (void) jsq_configureTextView
{
    [super jsq_configureTextView];
    
    self.layer.borderWidth = 0.5;
    self.layer.borderColor = [[[UIColor grayColor] colorWithAlphaComponent:0.5] CGColor];
    self.layer.cornerRadius = 15.0;
    
    self.textContainerInset = UIEdgeInsetsMake(4.0, 6.0, 4.0, 6.0);
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
                action == @selector(paste:) || action ==@selector(delete:)) {
                canPerform = YES;
            }
        } else {
            if ( action == @selector(select:) || action == @selector(selectAll:) ||
                action == @selector(paste:)) {
                canPerform = YES;
            }
        }
    }
    
    ZNGLogVerbose(@"Returning %@ for %@ %@", canPerform ? @"YES" : @"NO", NSStringFromSelector(_cmd), NSStringFromSelector(action));
    
    return canPerform;
}

@end
