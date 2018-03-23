//
//  ZNGConversationCellIncoming.m
//  Pods
//
//  Created by Jason Neel on 12/22/16.
//
//

#import "ZNGConversationCellIncoming.h"

@import SBObjectiveCWrapper;

@implementation ZNGConversationCellIncoming
{
    CALayer * mediaMask;
}

- (void) setMediaViewMaskingImage:(UIImage *)mediaViewMaskingImage
{
    _mediaViewMaskingImage = mediaViewMaskingImage;
    
    if (self.mediaView != nil) {
        mediaMask = [[CALayer alloc] init];
        mediaMask.contents = (id)[mediaViewMaskingImage CGImage];
        mediaMask.contentsScale = mediaViewMaskingImage.scale;
        
        if ((mediaViewMaskingImage.size.height > 0.0) && (mediaViewMaskingImage.size.width > 0.0)) {
            mediaMask.contentsCenter = CGRectMake(mediaViewMaskingImage.capInsets.left / mediaViewMaskingImage.size.width,
                                                  mediaViewMaskingImage.capInsets.top / mediaViewMaskingImage.size.height,
                                                  (mediaViewMaskingImage.size.width - mediaViewMaskingImage.capInsets.right - mediaViewMaskingImage.capInsets.left) / mediaViewMaskingImage.size.width,
                                                  (mediaViewMaskingImage.size.height - mediaViewMaskingImage.capInsets.bottom - mediaViewMaskingImage.capInsets.top) / mediaViewMaskingImage.size.height);
            
        }
        
        [self applyMediaViewMask];
    }
}

- (void) applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    SBLogVerbose(@"Before layout attributes: Mediaview is %@, its layer is %@, and its layer mask is %@", NSStringFromCGSize(self.mediaView.frame.size), NSStringFromCGSize(self.mediaView.layer.frame.size), NSStringFromCGSize(self.mediaView.layer.mask.frame.size));
    
    [super applyLayoutAttributes:layoutAttributes];
    
    SBLogVerbose(@"After layout attributes: Mediaview is %@, its layer is %@, and its layer mask is %@", NSStringFromCGSize(self.mediaView.frame.size), NSStringFromCGSize(self.mediaView.layer.frame.size), NSStringFromCGSize(self.mediaView.layer.mask.frame.size));
    
    // This delay shows a flaw in my understanding of the collection view cell lifecycle.  Removing this delay causes the media view layer mask to remain in its initial, small
    //  size until the device is redrawn.  Shame on me.  #fornow
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self applyMediaViewMask];
        
        SBLogVerbose(@"After after layout attributes: Mediaview is %@, its layer is %@, and its layer mask is %@", NSStringFromCGSize(self.mediaView.frame.size), NSStringFromCGSize(self.mediaView.layer.frame.size), NSStringFromCGSize(self.mediaView.layer.mask.frame.size));
    });
}

- (NSLayoutConstraint *) mediaViewLeftnessConstraint
{
    __block NSLayoutConstraint * leftness = nil;
    
    [[self.mediaView constraintsAffectingLayoutForAxis:UILayoutConstraintAxisHorizontal] enumerateObjectsUsingBlock:^(__kindof NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ((constraint.secondItem == self.mediaView) && (constraint.secondAttribute == NSLayoutAttributeLeading)) {
            leftness = constraint;
            *stop = YES;
        }
    }];
    
    return leftness;
}

- (void) setMediaView:(UIView *)mediaView
{
    [self.mediaView removeFromSuperview];
    [super setMediaView:mediaView];
    
    // We need to shimmy our media views rightward for incoming media messages.  This is due to some very complicated relationships
    //  between layer masks, resizeable images, cap insets, and the JSQMessagesViewController library.
    // Trust me, this is easier.
    // Removing this makes the images brush up against the avatars in incoming messges.
    [[self mediaViewLeftnessConstraint] setConstant:-6.0];
    [self.mediaView.superview layoutIfNeeded];
    
    if (mediaMask != nil) {
        [self applyMediaViewMask];
    }
}

- (void) applyMediaViewMask
{
    mediaMask.frame = self.mediaView.layer.bounds;
    
    self.mediaView.layer.mask = mediaMask;
    self.mediaView.layer.masksToBounds = YES;
    
    SBLogDebug(@"%p Setting a %@ mask with contentsCenter of %@ onto a %@ %@ media view", self, NSStringFromCGSize(mediaMask.frame.size), NSStringFromCGRect(mediaMask.contentsCenter), NSStringFromCGSize(self.mediaView.frame.size), [self.mediaView class]);
}

@end
