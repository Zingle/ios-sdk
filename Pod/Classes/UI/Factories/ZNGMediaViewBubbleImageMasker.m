
#import "ZNGMediaViewBubbleImageMasker.h"

#import "ZNGBubbleImageFactory.h"


@interface ZNGMediaViewBubbleImageMasker ()

- (void)zng_maskView:(UIView *)view withImage:(UIImage *)image;

@end


@implementation ZNGMediaViewBubbleImageMasker

#pragma mark - Initialization

- (instancetype)init
{
    return [self initWithBubbleImageFactory:[[ZNGBubbleImageFactory alloc] init]];
}

- (instancetype)initWithBubbleImageFactory:(ZNGBubbleImageFactory *)bubbleImageFactory
{
    NSParameterAssert(bubbleImageFactory != nil);
    
    self = [super init];
    if (self) {
        _bubbleImageFactory = bubbleImageFactory;
    }
    return self;
}

#pragma mark - View masking

- (void)applyOutgoingBubbleImageMaskToMediaView:(UIView *)mediaView
{
    ZNGBubbleImage *bubbleImageData = [self.bubbleImageFactory outgoingMessagesBubbleImageWithColor:[UIColor whiteColor]];
    [self zng_maskView:mediaView withImage:[bubbleImageData messageBubbleImage]];
}

- (void)applyIncomingBubbleImageMaskToMediaView:(UIView *)mediaView
{
    ZNGBubbleImage *bubbleImageData = [self.bubbleImageFactory incomingMessagesBubbleImageWithColor:[UIColor whiteColor]];
    [self zng_maskView:mediaView withImage:[bubbleImageData messageBubbleImage]];
}

+ (void)applyBubbleImageMaskToMediaView:(UIView *)mediaView isOutgoing:(BOOL)isOutgoing
{
    ZNGMediaViewBubbleImageMasker *masker = [[ZNGMediaViewBubbleImageMasker alloc] init];
    
    if (isOutgoing) {
        [masker applyOutgoingBubbleImageMaskToMediaView:mediaView];
    }
    else {
        [masker applyIncomingBubbleImageMaskToMediaView:mediaView];
    }
}

#pragma mark - Private

- (void)zng_maskView:(UIView *)view withImage:(UIImage *)image
{
    NSParameterAssert(view != nil);
    NSParameterAssert(image != nil);
    
    UIImageView *imageViewMask = [[UIImageView alloc] initWithImage:image];
    imageViewMask.frame = CGRectInset(view.frame, 2.0f, 2.0f);
    
    view.layer.mask = imageViewMask.layer;
}

@end
