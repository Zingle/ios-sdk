
#import "ZNGBubbleImageFactory.h"

#import "UIImage+ZingleSDK.h"
#import "UIColor+ZingleSDK.h"


@interface ZNGBubbleImageFactory ()

@property (strong, nonatomic, readonly) UIImage *bubbleImage;
@property (assign, nonatomic, readonly) UIEdgeInsets capInsets;

- (UIEdgeInsets)zng_centerPointEdgeInsetsForImageSize:(CGSize)bubbleImageSize;

- (ZNGBubbleImage *)zng_messagesBubbleImageWithColor:(UIColor *)color flippedForIncoming:(BOOL)flippedForIncoming;

- (UIImage *)zng_horizontallyFlippedImageFromImage:(UIImage *)image;

- (UIImage *)zng_stretchableImageFromImage:(UIImage *)image withCapInsets:(UIEdgeInsets)capInsets;

@end



@implementation ZNGBubbleImageFactory

#pragma mark - Initialization

- (instancetype)initWithBubbleImage:(UIImage *)bubbleImage capInsets:(UIEdgeInsets)capInsets
{
	NSParameterAssert(bubbleImage != nil);
    
	self = [super init];
	if (self) {
		_bubbleImage = bubbleImage;
        
        if (UIEdgeInsetsEqualToEdgeInsets(capInsets, UIEdgeInsetsZero)) {
            _capInsets = [self zng_centerPointEdgeInsetsForImageSize:bubbleImage.size];
        }
        else {
            _capInsets = capInsets;
        }
	}
	return self;
}

- (instancetype)init
{
    return [self initWithBubbleImage:[UIImage zng_bubbleCompactImage] capInsets:UIEdgeInsetsZero];
}

- (void)dealloc
{
    _bubbleImage = nil;
}

#pragma mark - Public

- (ZNGBubbleImage *)outgoingMessagesBubbleImageWithColor:(UIColor *)color
{
    return [self zng_messagesBubbleImageWithColor:color flippedForIncoming:NO];
}

- (ZNGBubbleImage *)incomingMessagesBubbleImageWithColor:(UIColor *)color
{
    return [self zng_messagesBubbleImageWithColor:color flippedForIncoming:YES];
}

#pragma mark - Private

- (UIEdgeInsets)zng_centerPointEdgeInsetsForImageSize:(CGSize)bubbleImageSize
{
    // make image stretchable from center point
    CGPoint center = CGPointMake(bubbleImageSize.width / 2.0f, bubbleImageSize.height / 2.0f);
    return UIEdgeInsetsMake(center.y, center.x, center.y, center.x);
}

- (ZNGBubbleImage *)zng_messagesBubbleImageWithColor:(UIColor *)color flippedForIncoming:(BOOL)flippedForIncoming
{
    NSParameterAssert(color != nil);
    
    UIImage *normalBubble = [self.bubbleImage zng_imageMaskedWithColor:color];
    UIImage *highlightedBubble = [self.bubbleImage zng_imageMaskedWithColor:[color zng_colorByDarkeningColorWithValue:0.12f]];
    
    if (flippedForIncoming) {
        normalBubble = [self zng_horizontallyFlippedImageFromImage:normalBubble];
        highlightedBubble = [self zng_horizontallyFlippedImageFromImage:highlightedBubble];
    }
    
    normalBubble = [self zng_stretchableImageFromImage:normalBubble withCapInsets:self.capInsets];
    highlightedBubble = [self zng_stretchableImageFromImage:highlightedBubble withCapInsets:self.capInsets];
    
    return [[ZNGBubbleImage alloc] initWithMessageBubbleImage:normalBubble highlightedImage:highlightedBubble];
}

- (UIImage *)zng_horizontallyFlippedImageFromImage:(UIImage *)image
{
    return [UIImage imageWithCGImage:image.CGImage
                               scale:image.scale
                         orientation:UIImageOrientationUpMirrored];
}

- (UIImage *)zng_stretchableImageFromImage:(UIImage *)image withCapInsets:(UIEdgeInsets)capInsets
{
    return [image resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];
}

@end
