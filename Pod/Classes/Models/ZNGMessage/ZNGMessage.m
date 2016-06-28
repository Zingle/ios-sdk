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

static const int zngLogLevel = ZNGLogLevelInfo;

@implementation ZNGMessage
{
    UIImageView * imageView;
    JSQMessagesMediaPlaceholderView * mediaPlaceholder;
}

#pragma mark - Initialization
- (instancetype) initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    
    if (self != nil) {
        if ([self isMediaMessage]) {
            mediaPlaceholder = [JSQMessagesMediaPlaceholderView viewWithActivityIndicator];
            [self createMediaItem];
        }
    }
    
    return self;
}

- (void) createMediaItem
{
    // We only support images for now.
    NSString * path = [self.attachments firstObject];
    NSURL * url = [NSURL URLWithString:path];
    
    if (url == nil) {
        ZNGLogWarn(@"Unable to parse URL for message attachment: %@", path);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSData * imageData = [NSData dataWithContentsOfURL:url];
        
        if (imageData == nil) {
            ZNGLogWarn(@"Unable to retrieve image data for message attachment from %@", path);
            return;
        }
        
        UIImage * image = [[UIImage alloc] initWithData:imageData];
        UIImageView * theImageView = [[UIImageView alloc] initWithImage:image];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            imageView = theImageView;
            [[NSNotificationCenter defaultCenter] postNotificationName:kZNGMessageMediaLoadedNotification object:self];
        });
    });
}

#pragma mark - Utility
- (BOOL) isEqual:(ZNGMessage *)other
{
    if (![other isKindOfClass:[ZNGMessage class]]) {
        return NO;
    }
    
    return (self.messageId == other.messageId);
}

- (NSUInteger)hash
{
    return [self.messageId hash];
}

- (BOOL) isOutbound
{
    return [self.communicationDirection isEqualToString:@"outbound"];
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

- (id<JSQMessageMediaData>)media
{
    return self;
}

#pragma mark - Message media data for <JSQMessageMediaData>
/**
 *  @return An initialized `UIView` object that represents the data for this media object.
 *
 *  @discussion You may return `nil` from this method while the media data is being downloaded.
 */
- (UIView *)mediaView
{
    return imageView;
}

/**
 *  @return The frame size for the mediaView when displayed in a `JSQMessagesCollectionViewCell`.
 *
 *  @discussion You should return an appropriate size value to be set for the mediaView's frame
 *  based on the contents of the view, and the frame and layout of the `JSQMessagesCollectionViewCell`
 *  in which mediaView will be displayed.
 *
 *  @warning You must return a size with non-zero, positive width and height values.
 */
- (CGSize)mediaViewDisplaySize
{
    return (imageView.image != nil) ? imageView.image.size : mediaPlaceholder.frame.size;
}

/**
 *  @return A placeholder media view to be displayed if mediaView is not yet available, or `nil`.
 *  For example, if mediaView will be constructed based on media data that must be downloaded,
 *  this placeholder view will be used until mediaView is not `nil`.
 *
 *  @discussion If you do not need support for a placeholder view, then you may simply return the
 *  same value here as mediaView. Otherwise, consider using `JSQMessagesMediaPlaceholderView`.
 *
 *  @warning You must not return `nil` from this method.
 *
 *  @see JSQMessagesMediaPlaceholderView.
 */
- (UIView *)mediaPlaceholderView
{
    return mediaPlaceholder;
}

/**
 *  @return An integer that can be used as a table address in a hash table structure.
 *
 *  @discussion This value must be unique for each media item with distinct contents.
 *  This value is used to cache layout information in the collection view.
 */
- (NSUInteger)mediaHash
{
    return [self hash];
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
             @"readAt" : @"read_at"
             };
}

+ (NSValueTransformer*)senderJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGCorrespondent.class];
}

+ (NSValueTransformer*)recipientJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGCorrespondent.class];
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
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGUser.class];
}

@end
