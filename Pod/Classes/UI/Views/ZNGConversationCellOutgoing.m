//
//  ZNGConversationCellOutgoing.m
//  Pods
//
//  Created by Jason Neel on 12/22/16.
//
//

#import "ZNGConversationCellOutgoing.h"
#import "UIColor+ZingleSDK.h"

@import SBObjectiveCWrapper;

@implementation ZNGConversationCellOutgoing
{
    CALayer * mediaMask;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.sendingErrorIconContainer.layer.cornerRadius = CGRectGetWidth(self.sendingErrorIconContainer.bounds) / 2.0;
    self.sendingErrorIcon.tintColor = [UIColor zng_strawberry]; // IB is ignoring the tintColor property in the xib for Xcode reasons
}

- (void) prepareForReuse
{
    [super prepareForReuse];
    self.sendingErrorIconContainer.hidden = YES;
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

- (void) setMediaView:(UIView *)mediaView
{
    [self.mediaView removeFromSuperview];
    [super setMediaView:mediaView];
    
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
