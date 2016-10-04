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
    BOOL startedDownloadingAttachments;
}

#pragma mark - Initialization
- (instancetype) initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    
    if (self != nil) {
        if ([self isMediaMessage]) {
            [self downloadAttachmentsIfNecessary];
        }
    }
    
    return self;
}

- (void) downloadAttachmentsIfNecessary
{
    if (startedDownloadingAttachments) {
        return;
    }
    
    startedDownloadingAttachments = YES;
    
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
        
        UIImage * theImage = [[UIImage alloc] initWithData:imageData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.image = theImage;
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
    
    return ([self.messageId isEqualToString:other.messageId]);
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
             @"imageAttachments" : [NSNull null],
             @"imageDownloadingQueue" : [NSNull null]
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
