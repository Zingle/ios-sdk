//
//  JSQMessagesCollectionViewCell+LayoutHack.m
//  Pods
//
//  Created by Jason Neel on 1/5/17.
//
//

// See https://github.com/jessesquires/JSQMessagesViewController/issues/817 for more than you probably care to know.
// This re-implementation of applyLayoutAttributes: adds some frame manipulation before the constraint adjustments, avoiding a ton of
//  unsatisfiable constraint log warnings and probable performance issues.

#import "JSQMessagesCollectionViewCell+LayoutHack.h"
#import <JSQMessagesViewController/JSQMessagesCollectionViewLayoutAttributes.h>
#import <JSQMessagesViewController/JSQMessagesCollectionViewCell.h>
#import <JSQMessagesViewController/JSQMessagesCollectionViewCellIncoming.h>
#import <JSQMessagesViewController/JSQMessagesCollectionViewCellOutgoing.h>
#import <objc/runtime.h>

@interface JSQMessagesCollectionViewCell (WhyAreThesePropertiesPrivate)

@property (weak, nonatomic) IBOutlet NSLayoutConstraint * messageBubbleContainerWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * cellTopLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * messageBubbleTopLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * cellBottomLabelHeightConstraint;
@property (assign, nonatomic) UIEdgeInsets textViewFrameInsets;
@property (assign, nonatomic) CGSize avatarViewSize;

@end

@interface JSQMessagesCollectionViewCell (PrivateMethods)
- (void)jsq_updateConstraint:(NSLayoutConstraint *)constraint withConstant:(CGFloat)constant;
@end

@implementation JSQMessagesCollectionViewCell (WhyAreThesePropertiesPrivate)

@dynamic avatarViewSize;
@dynamic cellBottomLabelHeightConstraint;
@dynamic cellTopLabelHeightConstraint;
@dynamic messageBubbleContainerWidthConstraint;
@dynamic messageBubbleTopLabelHeightConstraint;
@dynamic textViewFrameInsets;

@end

@implementation JSQMessagesCollectionViewCell (LayoutHack)

+ (void) load
{
    IMP replacementApplyLayoutAttributes = (IMP)_applyLayoutAttributes;
    Method applyLayoutAttributesMethod = class_getInstanceMethod(self, @selector(applyLayoutAttributes:));
    method_setImplementation(applyLayoutAttributesMethod, replacementApplyLayoutAttributes);
}

void _applyLayoutAttributes(id self, SEL _cmd, UICollectionViewLayoutAttributes * layoutAttributes)
{
    [self __replacementApplyLayoutAttributes:layoutAttributes];
}

- (void)__replacementApplyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    [super applyLayoutAttributes:layoutAttributes];
    
    JSQMessagesCollectionViewLayoutAttributes *customAttributes = (JSQMessagesCollectionViewLayoutAttributes *)layoutAttributes;
    
    if (self.textView.font != customAttributes.messageBubbleFont) {
        self.textView.font = customAttributes.messageBubbleFont;
    }
    
    if (!UIEdgeInsetsEqualToEdgeInsets(self.textView.textContainerInset, customAttributes.textViewTextContainerInsets)) {
        self.textView.textContainerInset = customAttributes.textViewTextContainerInsets;
    }
    
    self.textViewFrameInsets = customAttributes.textViewFrameInsets;
    
    BOOL sameHeight = ((self.messageBubbleContainerWidthConstraint.constant == customAttributes.messageBubbleContainerViewWidth)
                       && (self.cellTopLabelHeightConstraint.constant == customAttributes.cellTopLabelHeight)
                       && (self.messageBubbleTopLabelHeightConstraint.constant == customAttributes.messageBubbleTopLabelHeight)
                       && (self.cellBottomLabelHeightConstraint.constant == customAttributes.cellBottomLabelHeight));
    
    // https://github.com/jessesquires/JSQMessagesViewController/issues/817
    // Fix for layout issues
    if (!sameHeight) {
        CGRect bounds = self.contentView.bounds;
        bounds.size.height = [UIScreen mainScreen].bounds.size.height;
        self.contentView.bounds = bounds;
    }
    
    [self jsq_updateConstraint:self.messageBubbleContainerWidthConstraint
                  withConstant:customAttributes.messageBubbleContainerViewWidth];
    
    [self jsq_updateConstraint:self.cellTopLabelHeightConstraint
                  withConstant:customAttributes.cellTopLabelHeight];
    
    [self jsq_updateConstraint:self.messageBubbleTopLabelHeightConstraint
                  withConstant:customAttributes.messageBubbleTopLabelHeight];
    
    [self jsq_updateConstraint:self.cellBottomLabelHeightConstraint
                  withConstant:customAttributes.cellBottomLabelHeight];
    
    if ([self isKindOfClass:[JSQMessagesCollectionViewCellIncoming class]]) {
        self.avatarViewSize = customAttributes.incomingAvatarViewSize;
    }
    else if ([self isKindOfClass:[JSQMessagesCollectionViewCellOutgoing class]]) {
        self.avatarViewSize = customAttributes.outgoingAvatarViewSize;
    }
}


@end
