

#import "ZNGCollectionViewLayoutAttributes.h"


@interface ZNGCollectionViewLayoutAttributes ()

- (CGSize)zng_correctedAvatarSizeFromSize:(CGSize)size;

- (CGFloat)zng_correctedLabelHeightForHeight:(CGFloat)height;

@end


@implementation ZNGCollectionViewLayoutAttributes

#pragma mark - Lifecycle

- (void)dealloc
{
    _messageBubbleFont = nil;
}

#pragma mark - Setters

- (void)setMessageBubbleFont:(UIFont *)messageBubbleFont
{
    NSParameterAssert(messageBubbleFont != nil);
    _messageBubbleFont = messageBubbleFont;
}

- (void)setMessageBubbleContainerViewWidth:(CGFloat)messageBubbleContainerViewWidth
{
    NSParameterAssert(messageBubbleContainerViewWidth > 0.0f);
    _messageBubbleContainerViewWidth = ceilf(messageBubbleContainerViewWidth);
}

- (void)setIncomingAvatarViewSize:(CGSize)incomingAvatarViewSize
{
    NSParameterAssert(incomingAvatarViewSize.width >= 0.0f && incomingAvatarViewSize.height >= 0.0f);
    _incomingAvatarViewSize = [self zng_correctedAvatarSizeFromSize:incomingAvatarViewSize];
}

- (void)setOutgoingAvatarViewSize:(CGSize)outgoingAvatarViewSize
{
    NSParameterAssert(outgoingAvatarViewSize.width >= 0.0f && outgoingAvatarViewSize.height >= 0.0f);
    _outgoingAvatarViewSize = [self zng_correctedAvatarSizeFromSize:outgoingAvatarViewSize];
}

- (void)setCellTopLabelHeight:(CGFloat)cellTopLabelHeight
{
    NSParameterAssert(cellTopLabelHeight >= 0.0f);
    _cellTopLabelHeight = [self zng_correctedLabelHeightForHeight:cellTopLabelHeight];
}

- (void)setMessageBubbleTopLabelHeight:(CGFloat)messageBubbleTopLabelHeight
{
    NSParameterAssert(messageBubbleTopLabelHeight >= 0.0f);
    _messageBubbleTopLabelHeight = [self zng_correctedLabelHeightForHeight:messageBubbleTopLabelHeight];
}

- (void)setCellBottomLabelHeight:(CGFloat)cellBottomLabelHeight
{
    NSParameterAssert(cellBottomLabelHeight >= 0.0f);
    _cellBottomLabelHeight = [self zng_correctedLabelHeightForHeight:cellBottomLabelHeight];
}

#pragma mark - Utilities

- (CGSize)zng_correctedAvatarSizeFromSize:(CGSize)size
{
    return CGSizeMake(ceilf(size.width), ceilf(size.height));
}

- (CGFloat)zng_correctedLabelHeightForHeight:(CGFloat)height
{
    return ceilf(height);
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    if (self.representedElementCategory == UICollectionElementCategoryCell) {
        ZNGCollectionViewLayoutAttributes *layoutAttributes = (ZNGCollectionViewLayoutAttributes *)object;
        
        if (![layoutAttributes.messageBubbleFont isEqual:self.messageBubbleFont]
            || !UIEdgeInsetsEqualToEdgeInsets(layoutAttributes.textViewFrameInsets, self.textViewFrameInsets)
            || !UIEdgeInsetsEqualToEdgeInsets(layoutAttributes.textViewTextContainerInsets, self.textViewTextContainerInsets)
            || !CGSizeEqualToSize(layoutAttributes.incomingAvatarViewSize, self.incomingAvatarViewSize)
            || !CGSizeEqualToSize(layoutAttributes.outgoingAvatarViewSize, self.outgoingAvatarViewSize)
            || (int)layoutAttributes.messageBubbleContainerViewWidth != (int)self.messageBubbleContainerViewWidth
            || (int)layoutAttributes.cellTopLabelHeight != (int)self.cellTopLabelHeight
            || (int)layoutAttributes.messageBubbleTopLabelHeight != (int)self.messageBubbleTopLabelHeight
            || (int)layoutAttributes.cellBottomLabelHeight != (int)self.cellBottomLabelHeight) {
            return NO;
        }
    }
    
    return [super isEqual:object];
}

- (NSUInteger)hash
{
    return [self.indexPath hash];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    ZNGCollectionViewLayoutAttributes *copy = [super copyWithZone:zone];
    
    if (copy.representedElementCategory != UICollectionElementCategoryCell) {
        return copy;
    }
    
    copy.messageBubbleFont = self.messageBubbleFont;
    copy.messageBubbleContainerViewWidth = self.messageBubbleContainerViewWidth;
    copy.textViewFrameInsets = self.textViewFrameInsets;
    copy.textViewTextContainerInsets = self.textViewTextContainerInsets;
    copy.incomingAvatarViewSize = self.incomingAvatarViewSize;
    copy.outgoingAvatarViewSize = self.outgoingAvatarViewSize;
    copy.cellTopLabelHeight = self.cellTopLabelHeight;
    copy.messageBubbleTopLabelHeight = self.messageBubbleTopLabelHeight;
    copy.cellBottomLabelHeight = self.cellBottomLabelHeight;
    
    return copy;
}

@end
