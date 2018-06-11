//
//  ZNGNewMessage.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGNewMessage.h"
#import "ZNGCorrespondent.h"
#import "NSData+ImageType.h"
#import "UIImage+animatedGIF.h"

@import SBObjectiveCWrapper;

static const CGFloat ImageAttachmentMaxHeight = 800.0;
static const CGFloat ImageAttachmentMaxWidth = 800.0;

static NSString * const AttachmentContentTypeKey = @"content_type";
static NSString * const AttachementBase64 = @"base64";

@implementation ZNGNewMessage

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"senderType" : @"sender_type",
             @"sender" : @"sender",
             @"recipientType" : @"recipient_type",
             @"recipients" : @"recipients",
             @"channelTypeIds" : @"channel_type_ids",
             @"body" : @"body",
             @"attachments" : @"attachments",
             @"uuid" : @"uuid"
             };
}

+ (NSValueTransformer*)senderJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ZNGParticipant class]];
}

+ (NSValueTransformer*)recipientsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGParticipant class]];
}

- (void) attachImageData:(NSData *)originalImageData withMaximumSize:(CGSize)theMaxSize removingExisting:(BOOL)removeExisting
{
    if ([originalImageData length] == 0) {
        SBLogWarning(@"%s called with no imageData.  Ignoring.", __PRETTY_FUNCTION__);
        return;
    }
    
    CGSize maxSize = theMaxSize;
    
    if (CGSizeEqualToSize(maxSize, CGSizeZero)) {
        maxSize = CGSizeMake(ImageAttachmentMaxWidth, ImageAttachmentMaxHeight);
    }
    
    NSMutableArray<UIImage *> * mutableOutgoingImages = [[NSMutableArray alloc] init];
    NSMutableArray<NSDictionary *> * mutableAttachments = [[NSMutableArray alloc] init];
    
    // Do we need to grab our preexisting attachments?
    if (!removeExisting) {
        void (^grabExistingAttachments)(void) = ^{
            if ([self.outgoingImageAttachments count] > 0) {
                [mutableOutgoingImages addObjectsFromArray:self.outgoingImageAttachments];
            }
            
            if ([self.attachments count] > 0) {
                [mutableAttachments addObjectsFromArray:self.attachments];
            }
        };
        
        if ([[NSThread currentThread] isMainThread]) {
            // We're already on the main thread.  Do it here.
            grabExistingAttachments();
        } else {
            // Hop over onto the main thread and grab existing attachments.
            dispatch_sync(dispatch_get_main_queue(), ^{
                grabExistingAttachments();
            });
        }
    }

    NSData * imageData = originalImageData;
    NSString * contentType = [originalImageData imageContentType];
    UIImage * imageForLocalDisplay;
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFTypeRef)imageData, NULL);
    size_t const frameCount = CGImageSourceGetCount(imageSource);
    CFRelease(imageSource);
    
    if (frameCount > 1) {
        // This is an animated GIF.
        imageForLocalDisplay = [UIImage animatedImageWithAnimatedGIFData:originalImageData];
        contentType = NSDataImageContentTypeGif;
    } else {
        // This is a single frame image.
        imageForLocalDisplay = [[UIImage alloc] initWithData:imageData];
        
        // Do we need to resize?
        BOOL needsResize = ((imageForLocalDisplay.size.width > maxSize.width) || (imageForLocalDisplay.size.height > maxSize.height));
        
        if (needsResize) {
            NSData * resizeData = [self resizedJpegImageDataForImage:imageForLocalDisplay withMaxSize:maxSize];
            
            if (resizeData != nil) {
                imageData = resizeData;
                contentType = NSDataImageContentTypeJpeg;
            } else {
                SBLogError(@"Unable to resize %@ image before sending.  It will be sent in its original form.", NSStringFromCGSize(imageForLocalDisplay.size));
            }
        }
    }
    
    // We have a (maybe resized) imageData to send and imageForLocalDisplay
    // Now for the base64 encoding:
    NSData * base64Data = [imageData base64EncodedDataWithOptions:0];
    NSString * base64String = [[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding];
    NSDictionary * attachment = @{ AttachmentContentTypeKey: contentType, AttachementBase64: base64String };
    
    [mutableAttachments addObject:attachment];
    [mutableOutgoingImages addObject:imageForLocalDisplay];
    
    // Ensure we are on the main thread to put our work in place
    void (^putWorkInPlace)(void) = ^{
        self.outgoingImageAttachments = mutableOutgoingImages;
        self.attachments = mutableAttachments;
    };
    
    if ([[NSThread currentThread] isMainThread]) {
        putWorkInPlace();
    } else {
        dispatch_sync(dispatch_get_main_queue(), putWorkInPlace);
    }
}

-(NSData *)resizedJpegImageDataForImage:(UIImage *)image withMaxSize:(CGSize)maxSize
{
    // Sanity check
    if ((image.size.height == 0) || (image.size.width == 0)) {
        return nil;
    }
    
    // If the image is animated, abandon all hope (of resize)
    if ([image.images count] > 1) {
        return nil;
    }
    
    CGFloat widthDownscale = maxSize.width / image.size.width;
    CGFloat heightDownscale = maxSize.height / image.size.height;
    CGFloat downscale = MIN(widthDownscale, heightDownscale);
    
    if (downscale >= 1.0) {
        // No need to resize
        return nil;
    }
    
    CGFloat newWidth = image.size.width * downscale;
    CGFloat newHeight = image.size.height * downscale;
    
    CGRect rect = CGRectMake(0.0, 0.0, newWidth, newHeight);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    UIImage * resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    float compressionQuality = 0.5;
    NSData * imageData = UIImageJPEGRepresentation(resizedImage, compressionQuality);
    UIGraphicsEndImageContext();
    
    return imageData;
}

@end
