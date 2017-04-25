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
    // Has our image loaded?
    UIImage * image = self.event.message.imageAttachmentsByName[[self attachmentName]];
    
    // Outgoing image?
    if ((image == nil) && ([self.event.message.outgoingImageAttachments count] > self.index)) {
        image = self.event.message.outgoingImageAttachments[self.index];
    }
 
    if (image != nil) {
        UIImageView * imageView = [[UIImageView alloc] initWithImage:image];
        
        // Really we want aspect fit, but there are often some very small sizing mistakes when it comes to the interaction between the image sizing and the
        //  collection view layout calculations.  Since we are adding a rounded corner mask to the image view anyway, it's OK if we slightly crop the edges here.
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        ZNGLogVerbose(@"%@-%llu created and returned image view", self.event.eventId, (unsigned long long)self.index);
        return imageView;
    }
    
    // No media yet
    ZNGLogVerbose(@"%@-%llu has no image yet available.  Returning nil for media view.", self.event.eventId, (unsigned long long)self.index);
    return nil;
}

/**
 *  If our image has downloaded, this will reflect the actual image size, downsized within maximumImageDisplaySize to maintain aspect ratio.
 *  If our image has not yet loaded, but we have seen it previously, this will return its cached size.
 *  If neither of the above, maximumImageDisplaySize will be returned.
 */
- (CGSize)mediaViewDisplaySize
{
    CGSize size = CGSizeZero;
    NSString * attachmentName = [self attachmentName];
    UIImage * image;
    
    if (self.index < [self.event.message.outgoingImageAttachments count]) {
        image = self.event.message.outgoingImageAttachments[self.index];
    } else {
        image = self.event.message.imageAttachmentsByName[attachmentName];
    }
    
    if (image != nil) {
        size = image.size;
    } else {
        size = [[ZNGImageSizeCache sharedCache] sizeForImageWithPath:attachmentName];
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
    CGSize imageSize = [self mediaViewDisplaySize];
    UIView * placeholderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, imageSize.width, imageSize.height)];
    placeholderView.translatesAutoresizingMaskIntoConstraints = NO;
    placeholderView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.05];
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGEventViewModel class]];
    UIImage * placeholderIcon = [UIImage imageNamed:@"attachment" inBundle:bundle compatibleWithTraitCollection:nil];
    UIImageView * placeholderIconImageView = [[UIImageView alloc] initWithImage:placeholderIcon];
    placeholderIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    placeholderIconImageView.tintColor = [UIColor colorWithWhite:0.0 alpha:0.15];
    
    [placeholderView addSubview:placeholderIconImageView];
    
    NSLayoutConstraint * centerX = [NSLayoutConstraint constraintWithItem:placeholderIconImageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:placeholderView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    NSLayoutConstraint * centerY = [NSLayoutConstraint constraintWithItem:placeholderIconImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:placeholderView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    
    [placeholderView addConstraints:@[centerX, centerY]];
    ZNGLogVerbose(@"%@-%llu creating and returning media placeholder view", self.event.eventId, (unsigned long long)self.index);
    
    return placeholderView;
}

- (NSUInteger)mediaHash
{
    return [self hash];
}

@end
