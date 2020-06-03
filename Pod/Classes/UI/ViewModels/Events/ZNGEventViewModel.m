//
//  ZNGEventViewModel.m
//  Pods
//
//  Created by Jason Neel on 1/13/17.
//

#import "ZNGEventViewModel.h"
#import "ZNGEvent.h"
#import "ZNGImageSizeCache.h"
#import "ZNGEventMetadataEntry.h"

@import SBObjectiveCWrapper;
@import SDWebImage;

NSString * const ZNGEventViewModelImageSizeChangedNotification = @"ZNGEventViewModelImageSizeChangedNotification";

NSString * const ZNGEventMentionAttribute = @"ZNGEventMentionAttribute";
NSString * const ZNGEventUserMentionAttribute = @"ZNGEventUserMentionAttribute";
NSString * const ZNGEventTeamMentionAttribute = @"ZNGEventTeamMentionAttribute";

@implementation ZNGEventViewModel

- (id) initWithEvent:(ZNGEvent *)event index:(NSUInteger)index
{
    self = [super init];
    
    if (self != nil) {
        _event = event;
        _index = index;
        
        if ([self outgoingImageAttachment] != nil) {
            self.attachmentStatus = ZNGEventViewModelAttachmentStatusAvailable;
        } else if (([self attachmentName] != nil) && (![self attachmentIsSupported])) {
            self.attachmentStatus = ZNGEventViewModelAttachmentStatusUnrecognizedType;
        }
    }
    
    return self;
}

- (BOOL) attachmentIsSupported
{
    if ([self outgoingImageAttachment] != nil) {
        return YES;
    }
    
    NSString * attachmentPath = [self attachmentName];
    
    if (attachmentPath == nil) {
        return NO;
    }
    
    NSString * extension = [[[self attachmentName] pathExtension] lowercaseString];

    if (![[self recognizedAttachmentFileExtensions] containsObject:extension]) {
        SBLogInfo(@"Unsupported file extension (%@) for attachment: %@", extension, attachmentPath);
        return NO;
    }
    
    return YES;
}

- (NSArray<NSString *> *) recognizedAttachmentFileExtensions
{
    return @[@"png", @"jpg", @"jpeg", @"gif", @"tiff", @"bmp"];
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
        SBLogError(@"Our %@ index is %llu, but we only have %llu image attachments and %llu outgoing image attachments.  This is odd.", [self class], (unsigned long long)self.index, (unsigned long long)[self.event.message.attachments count], (unsigned long long)[self.event.message.outgoingImageAttachments count]);
        
        return nil;
    }
    
    NSString * attachmentName = self.event.message.attachments[self.index];
    
    // Ensure this is an NSString and not NSNull
    if ([attachmentName isKindOfClass:[NSString class]]) {
        return attachmentName;
    }
    
    return nil;
}

- (UIImage *) outgoingImageAttachment
{
    if (self.index >= [self.event.message.outgoingImageAttachments count]) {
        return nil;
    }
    
    return self.event.message.outgoingImageAttachments[self.index];
}

- (NSAttributedString *) attributedText
{
    NSMutableAttributedString * text = [[NSMutableAttributedString alloc] initWithString:self.text];
    
    for (ZNGEventMetadataEntry * metadata in self.event.metadata) {
        if ((metadata.start == nil) || (metadata.end == nil)) {
            SBLogError(@"Metadata entry has nil for either start (%@) or end (%@)", metadata.start, metadata.end);
            continue;
        }
        
        NSRange range = NSMakeRange([metadata.start unsignedIntegerValue], [metadata.end unsignedIntegerValue] - [metadata.start unsignedIntegerValue]);
        
        if ((range.location >= [text length]) || ((range.location + range.length) >= [text length])) {
            SBLogError(@"Metadata entry range is out of bounds of the event text: %@", metadata);
            continue;
        }
        
        NSString * uuid = metadata.uuid ?: @"null";
        
        [text addAttribute:ZNGEventMentionAttribute value:uuid range:range];
        
        if ([metadata.type isEqualToString:ZNGEventMetadataEntryMentionTypeUser]) {
            [text addAttribute:ZNGEventUserMentionAttribute value:uuid range:range];
        } else if ([metadata.type isEqualToString:ZNGEventMetadataEntryMentionTypeTeam]) {
            [text addAttribute:ZNGEventTeamMentionAttribute value:uuid range:range];
        }
    }

    return text;
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
    UIImage * outgoingAttachmenmt = [self outgoingImageAttachment];
    
    if (outgoingAttachmenmt != nil) {
        return [[UIImageView alloc] initWithImage:outgoingAttachmenmt];
    }
    
    if (([[self attachmentName] length] == 0) && ([self.event.message.outgoingImageAttachments count] == 0)) {
        return nil;
    }
    
    CGSize previouslyKnownImageSize = [self mediaViewDisplaySize];
    NSURL * attachmentURL = ([self attachmentIsSupported]) ? [NSURL URLWithString:[self attachmentName]] : nil;

    SDAnimatedImageView * animatedImageView = [[SDAnimatedImageView alloc] init];
    animatedImageView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.05];
    animatedImageView.tintColor = [self _placeholderTint];
    
    // Set content mode to center so our placeholder image is centered instead of stretched.  Content mode will be reset when the image loads.
    animatedImageView.contentMode = UIViewContentModeCenter;
    
    // Gogogo
    [animatedImageView sd_setImageWithURL:attachmentURL placeholderImage:[self _placeholderIcon] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        if (receivedSize < expectedSize) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.attachmentStatus = ZNGEventViewModelAttachmentStatusDownloading;
            });
        }
    } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image != nil) {
            self.attachmentStatus = ZNGEventViewModelAttachmentStatusAvailable;
            
            // Set the content mode back to fill
            animatedImageView.contentMode = UIViewContentModeScaleAspectFill;
            
            // If this size is new, post a notification
            if ((cacheType == SDImageCacheTypeNone) && (!CGSizeEqualToSize(previouslyKnownImageSize, image.size))) {
                // Save the image size to cache
                [[ZNGImageSizeCache sharedCache] setSize:image.size forImageWithPath:[self attachmentName]];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:ZNGEventViewModelImageSizeChangedNotification object:self];
            }
        } else if (imageURL != nil) {
            SBLogInfo(@"Setting event view model image view to %@ failed: %@", imageURL, error);
            self.attachmentStatus = ZNGEventViewModelAttachmentStatusFailed;
            
            // Ensure that the content mode is still center and the placeholder image is now a failed download image
            animatedImageView.contentMode = UIViewContentModeCenter;
            animatedImageView.tintColor = [self _placeholderTint];
            animatedImageView.image = [self _placeholderIcon];
        }
    }];
    
    return animatedImageView;
}

- (UIColor *) _placeholderTint
{
    if ((self.attachmentStatus == ZNGEventViewModelAttachmentStatusUnrecognizedType) || (self.attachmentStatus == ZNGEventViewModelAttachmentStatusFailed)) {
        return [UIColor colorWithWhite:0.0 alpha:0.5];
    }
    
    return [UIColor colorWithWhite:0.0 alpha:0.15];
}

- (UIImage *) _placeholderIcon
{
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGEventViewModel class]];

    if ((self.attachmentStatus == ZNGEventViewModelAttachmentStatusUnrecognizedType) || (self.attachmentStatus == ZNGEventViewModelAttachmentStatusFailed)) {
        return [UIImage imageNamed:@"sadCloud" inBundle:bundle compatibleWithTraitCollection:nil];
    }
    
    // Else we look good
    return [UIImage imageNamed:@"attachment" inBundle:bundle compatibleWithTraitCollection:nil];
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
