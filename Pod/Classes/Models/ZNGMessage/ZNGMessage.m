//
//  ZNGMessage.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGMessage.h"
#import "ZNGLogging.h"
#import "ZingleValueTransformers.h"
#import "JSQPhotoMediaItem.h"
#import "JSQMessagesMediaPlaceholderView.h"
#import "ZNGImageAttachment.h"
#import "UIColor+ZingleSDK.h"
#import "ZNGImageSizeCache.h"
#import "ZNGPlaceholderImageAttachment.h"

static const int zngLogLevel = ZNGLogLevelVerbose;

@implementation ZNGMessage
{
    BOOL startedDownloadingAttachments;
    
    NSAttributedString * attributedText;
    NSUInteger numLoadedImagesInAttributedText;
}

#pragma mark - Initialization
- (instancetype) initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    
    if (self != nil) {
        if ([self isMediaMessage]) {
            self.imageAttachmentsByName = [[NSMutableDictionary alloc] init];
            [self downloadAttachmentsIfNecessary];
        }
    }
    
    return self;
}

+ (dispatch_queue_t) imageDownloadingQueue
{
    static dispatch_once_t onceToken;
    static dispatch_queue_t queue;
    
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.zingleme.ZNGMessage.imageDownloadingQueue", 0);
        dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
    });
    
    return queue;
}

+ (NSValueTransformer *) bodyJSONTransformer
{
    return [MTLValueTransformer reversibleTransformerWithBlock:^NSString *(NSString * source) {
        if (source == nil) {
            return nil;
        }
        
        // Remove any attachment sentinel characters
        NSString * attachmentCharacters = [NSString stringWithFormat:@"%c\ufffc", NSAttachmentCharacter];
        NSCharacterSet * attachmentCharacterSet = [NSCharacterSet characterSetWithCharactersInString:attachmentCharacters];
        NSString * strippedString = [[source componentsSeparatedByCharactersInSet:attachmentCharacterSet] componentsJoinedByString:@""];
        
        return strippedString;
    }];
}

- (void) downloadAttachmentsIfNecessary
{
    if (startedDownloadingAttachments) {
        return;
    }
    
    startedDownloadingAttachments = YES;
    
    dispatch_async([[self class] imageDownloadingQueue], ^{
        for (NSString * path in self.attachments) {
            NSURL * url = [NSURL URLWithString:path];
            
            if (url == nil) {
                ZNGLogWarn(@"Unable to parse URL for message attachment: %@", path);
                return;
            }
            
            NSData * imageData = [NSData dataWithContentsOfURL:url];
            
            if (imageData == nil) {
                ZNGLogWarn(@"Unable to retrieve image data for message attachment from %@", path);
                return;
            }
            
            UIImage * theImage = [[UIImage alloc] initWithData:imageData];
            
            if (theImage == nil) {
                ZNGLogWarn(@"Unable to initialize an image from %llu bytes of attachment data.", (unsigned long long)[imageData length]);
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageAttachmentsByName[path] = theImage;
                [[NSNotificationCenter defaultCenter] postNotificationName:kZNGMessageMediaLoadedNotification object:self];
            });
        }
    });
}

#pragma mark - Utility
- (BOOL) isEqual:(ZNGMessage *)other
{
    if (![other isKindOfClass:[ZNGMessage class]]) {
        return NO;
    }
    
    if ([self.messageId isEqualToString:other.messageId]) {
        return YES;
    }
    
    // The server is sometimes neglecting to send us a message ID.  We can be pretty safe in saying that the message is the same if the date is the same.
    return ([self.createdAt isEqualToDate:other.createdAt]);
}

- (NSUInteger)hash
{
    return [self.messageId hash];
}

- (BOOL) isOutbound
{
    return [self.communicationDirection isEqualToString:@"outbound"];
}

- (NSString *) triggeredByUserIdOrSenderId
{
    return ([self.triggeredByUser.userId length] > 0) ? self.triggeredByUser.userId : self.sender.correspondentId;
}

- (ZNGCorrespondent *) contactCorrespondent
{
    return ([self isOutbound]) ? self.recipient : self.sender;
}

#pragma mark - Message data for <JSQMessageData>
- (NSString *)senderId
{
    return self.sender.correspondentId;
}

- (NSDate *)date
{
    return self.createdAt;
}

- (BOOL) isMediaMessage
{
    return ([self.attachments count] > 0);
}

- (NSUInteger)messageHash
{
    return [self.messageId hash];
}

- (NSString *)text
{
    return self.body;
}

- (NSAttributedString *) attributedText
{
    NSUInteger numLoadedImages = [self.imageAttachmentsByName count];

    if ((attributedText != nil) && (numLoadedImagesInAttributedText == [self.imageAttachmentsByName count])) {
        return attributedText;
    }
    
    NSString * nonWhitespaceBody = [self.body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    BOOL bodyPresent = ([nonWhitespaceBody length] > 0);
    NSString * bodyString = bodyPresent ? self.body : @"";
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:bodyString];
    
    __block NSUInteger outgoingImageAttachmentIndex = 0;
    
    // Attach images and placeholders
    [self.attachments enumerateObjectsUsingBlock:^(NSString *  _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImage * image;
        
        if ([path isKindOfClass:[NSNull class]]) {
            // This may be an outgoing message with attached images.
            if (outgoingImageAttachmentIndex < [self.outgoingImageAttachments count]) {
                image = self.outgoingImageAttachments[outgoingImageAttachmentIndex];
                outgoingImageAttachmentIndex++;
            }
        } else {
            image = self.imageAttachmentsByName[path];
        }
        
        ZNGImageAttachment * attachment;
        
        if (image != nil) {
            attachment = [[ZNGImageAttachment alloc] init];
            attachment.image = image;
            ZNGLogVerbose(@"Initializing a text attachment for %@", [path lastPathComponent]);
        } else {
            // We do not have the image loaded.  Load a placeholder.  Use correct size data if we have it cached.
            CGSize imageSize = [[ZNGImageSizeCache sharedCache] sizeForImageWithPath:path];
            attachment = [[ZNGPlaceholderImageAttachment alloc] initWithSize:imageSize];
            
            ZNGLogVerbose(@"Initializing a placeholder image attachment for %@", [path lastPathComponent]);
        }
        
        attachment.maxDisplayHeight = 200.0;
        
        
        NSString * spacingString = ([string length] > 0) ? @"\n\n" : @"";
        NSAttributedString * spacing = [[NSAttributedString alloc] initWithString:spacingString];
        NSAttributedString * imageString = [NSAttributedString attributedStringWithAttachment:attachment];
        [string appendAttributedString:spacing];
        [string appendAttributedString:imageString];
    }];
    
    attributedText = string;
    numLoadedImagesInAttributedText = numLoadedImages;
    
    return string;
}

#pragma mark - Serialization
+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"messageId" : @"id",
             @"body" : @"body",
             @"displayName" : @"display_name",
             @"communicationDirection" : @"communication_direction",
             @"bodyLanguageCode" : @"body_language_code",
             @"translatedBody" : @"translated_body",
             @"translatedBodyLanguageCode" : @"translated_body_language_code",
             @"triggeredByUserId" : @"triggered_by_user_id",
             @"triggeredByUser" : @"triggered_by_user",
             @"templateId" : @"template_id",
             @"senderType" : @"sender_type",
             @"sender" : @"sender",
             @"recipientType" : @"recipient_type",
             @"recipient" : @"recipient",
             @"attachments" : @"attachments",
             @"createdAt" : @"created_at",
             @"readAt" : @"read_at",
             @"sending" : [NSNull null],
             NSStringFromSelector(@selector(imageAttachmentsByName)) : [NSNull null],
             NSStringFromSelector(@selector(outgoingImageAttachments)) : [NSNull null]
             };
}

+ (NSValueTransformer*)senderJSONTransformer
{
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[ZNGCorrespondent class]];
}

+ (NSValueTransformer*)recipientJSONTransformer
{
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[ZNGCorrespondent class]];
}

+ (NSValueTransformer*)createdAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer*)readAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer*)triggeredByUserJSONTransformer
{
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[ZNGUser class]];
}

@end
