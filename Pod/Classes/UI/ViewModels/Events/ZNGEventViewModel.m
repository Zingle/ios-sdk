//
//  ZNGEventViewModel.m
//  Pods
//
//  Created by Jason Neel on 1/13/17.
//

#import "ZNGEventViewModel.h"
#import "ZNGEvent.h"
#import "ZNGImageSizeCache.h"
#import "ZNGLogging.h" 

@import SDWebImage;
@import FLAnimatedImage;

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGEventViewModel

- (id) initWithEvent:(ZNGEvent *)event index:(NSUInteger)index
{
    self = [super init];
    
    if (self != nil) {
        _event = event;
        _index = index;
    }
    
    return self;
}

- (NSUInteger) hash
{
    return [[self.event.eventId stringByAppendingFormat:@"%llu", (unsigned long long)self.index] hash];
}

- (BOOL) isEqual:(ZNGEventViewModel *)object
{
    if (![object isKindOfClass:[ZNGEventViewModel class]]) {
        return NO;
    }
    
    return ((self.index == object.index) && ([self.event.eventId isEqualToString:object.event.eventId]));
}

- (BOOL) exactImageSizeCalculated
{
    if (self.attachmentName == nil) {
        return NO;
    }
    
    return !CGSizeEqualToSize([[ZNGImageSizeCache sharedCache] sizeForImageWithPath:[self attachmentName]], CGSizeZero);
}

// Our text body will always be the last entry
- (NSUInteger) textIndex
{
    return [self.event.message.attachments count];
}

// The name/URL string of the attachment represented by this ZNGEventViewModel.  nil if this is a text entry.
- (NSString *) attachmentName
{
    if (self.index == [self textIndex]) {
        return nil;
    }
    
    // Are we within bounds for normal message attachments?
    if (self.index >= [self.event.message.attachments count]) {
        ZNGLogError(@"Our %@ index is %llu, but we only have %llu image attachments and %llu outgoing image attachments.  This is odd.", [self class], (unsigned long long)self.index, (unsigned long long)[self.event.message.attachments count], (unsigned long long)[self.event.message.outgoingImageAttachments count]);
        
        return nil;
    }
    
    return self.event.message.attachments[self.index];
}

#pragma mark - Image attachment sizing
- (CGSize) maximumImageDisplaySize
{
    CGFloat width = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? 300.0 : 200.0;
    return CGSizeMake(width, 200.0);
}

#pragma mark - JSQMessageData

- (NSString *)senderId
{
    return self.event.message.sender.correspondentId ?: self.event.triggeredByUser.userId;
}

- (NSString *)senderDisplayName
{
    return self.event.senderDisplayName;
}

- (NSDate *)date
{
    return self.event.createdAt;
}

- (BOOL)isMediaMessage
{
    return (self.index != [self textIndex]);
}

- (NSUInteger)messageHash
{
    return [self hash];
}

- (NSString *)text
{
    return [self.event text];
}

- (id<JSQMessageMediaData>)media
{
    return self;
}

#pragma mark - JSQMessageMediaData

- (UIView *)mediaView
{
    // If this is an outgoing image, we will return a UIImageView containing it.
    if ([self.event.message.outgoingImageAttachments count] > self.index) {
        UIImage * image = self.event.message.outgoingImageAttachments[self.index];
        return [[UIImageView alloc] initWithImage:image];
    }
    
    if (([[self attachmentName] length] == 0) && ([self.event.message.outgoingImageAttachments count] == 0)) {
        return nil;
    }
    
    CGSize previouslyKnownImageSize = [self mediaViewDisplaySize];
    
    // This is a normal image attachment.  We will set its URL via SDWebImage and plop a placeholder in place.
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGEventViewModel class]];
    UIImage * placeholderIcon = [UIImage imageNamed:@"attachment" inBundle:bundle compatibleWithTraitCollection:nil];
    
    NSURL * attachmentURL = [NSURL URLWithString:[self attachmentName]];
    
    FLAnimatedImageView * animatedImageView = [[FLAnimatedImageView alloc] init];
    animatedImageView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.05];
    animatedImageView.tintColor = [UIColor colorWithWhite:0.0 alpha:0.15];
    
    // Set content mode to center so our placeholder image is centered instead of stretched.  Content mode will be reset when the image loads.
    animatedImageView.contentMode = UIViewContentModeCenter;
    
    // Gogogo
    [animatedImageView sd_setImageWithURL:attachmentURL placeholderImage:placeholderIcon completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image != nil) {
            // Set the content mode back to fill
            animatedImageView.contentMode = UIViewContentModeScaleAspectFill;
            
            // Save the image size to cache
            [[ZNGImageSizeCache sharedCache] setSize:image.size forImageWithPath:[self attachmentName]];
        }
    }];
    
    return animatedImageView;
}

/**
 *  If our image has downloaded, this will reflect the actual image size, downsized within maximumImageDisplaySize to maintain aspect ratio.
 *  If our image has not yet loaded, but we have seen it previously, this will return its cached size.
 *  If neither of the above, maximumImageDisplaySize will be returned.
 */
- (CGSize)mediaViewDisplaySize
{
    CGSize size;
    
    if ([self.event.message.outgoingImageAttachments count] > self.index) {
        // This is an outgoing image attachment
        UIImage * image = self.event.message.outgoingImageAttachments[self.index];
        size = image.size;
    } else {
        size = [[ZNGImageSizeCache sharedCache] sizeForImageWithPath:[self attachmentName]];
    }
    
    if ((size.height == 0.0) || (size.width == 0.0)) {
        size = [self maximumImageDisplaySize];
    } else {
        // Downscale
        CGSize maximumSize = [self maximumImageDisplaySize];
        CGFloat widthDownscale = maximumSize.width / size.width;
        CGFloat heightDownscale = maximumSize.height / size.height;
        CGFloat downscale = MIN(widthDownscale, heightDownscale);
        
        if (downscale < 1.0) {
            size = CGSizeMake(size.width * downscale, size.height * downscale);
        }
    }
    
    return size;
}

- (UIView *)mediaPlaceholderView
{
    return nil;
}

- (NSUInteger)mediaHash
{
    return [self hash];
}

@end
