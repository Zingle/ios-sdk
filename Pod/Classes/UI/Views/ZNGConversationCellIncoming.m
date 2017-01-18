//
//  ZNGConversationCellIncoming.m
//  Pods
//
//  Created by Jason Neel on 12/22/16.
//
//

#import "ZNGConversationCellIncoming.h"
#import "ZNGLogging.h"

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGConversationCellIncoming
{
    UIEdgeInsets mediaMaskCapInsets;
    CALayer * mediaMask;
}

- (void) setMediaViewMaskingImage:(UIImage *)mediaViewMaskingImage
{
    _mediaViewMaskingImage = mediaViewMaskingImage;
    mediaMaskCapInsets = mediaViewMaskingImage.capInsets;
    
    if (self.mediaView != nil) {
        mediaMask = [[CALayer alloc] init];
        mediaMask.contents = (id)[mediaViewMaskingImage CGImage];
        mediaMask.contentsScale = mediaViewMaskingImage.scale;
        
        [self applyMediaViewMask];
    }
}

- (void) applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    ZNGLogVerbose(@"Before layout attributes: Mediaview is %@, its layer is %@, and its layer mask is %@", NSStringFromCGSize(self.mediaView.frame.size), NSStringFromCGSize(self.mediaView.layer.frame.size), NSStringFromCGSize(self.mediaView.layer.mask.frame.size));
    
    [super applyLayoutAttributes:layoutAttributes];
    
    ZNGLogVerbose(@"After layout attributes: Mediaview is %@, its layer is %@, and its layer mask is %@", NSStringFromCGSize(self.mediaView.frame.size), NSStringFromCGSize(self.mediaView.layer.frame.size), NSStringFromCGSize(self.mediaView.layer.mask.frame.size));
    
    // This delay shows a flaw in my understanding of the collection view cell lifecycle.  Removing this delay causes the media view layer mask to remain in its initial, small
    //  size until the device is redrawn.  Shame on me.  #fornow
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self applyMediaViewMask];
        
        ZNGLogVerbose(@"After after layout attributes: Mediaview is %@, its layer is %@, and its layer mask is %@", NSStringFromCGSize(self.mediaView.frame.size), NSStringFromCGSize(self.mediaView.layer.frame.size), NSStringFromCGSize(self.mediaView.layer.mask.frame.size));
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
    mediaMask.contentsCenter = CGRectMake(mediaMaskCapInsets.left / mediaMask.frame.size.width,
                                          mediaMaskCapInsets.top / mediaMask.frame.size.height,
                                          1.0 / mediaMask.frame.size.width,
                                          1.0/ mediaMask.frame.size.height);
    self.mediaView.layer.mask = mediaMask;
    self.mediaView.layer.masksToBounds = YES;
    
    ZNGLogDebug(@"Setting a %@ mask onto a %@ %@ media view", NSStringFromCGSize(mediaMask.frame.size), NSStringFromCGSize(self.mediaView.frame.size), [self.mediaView class]);
}

@end
