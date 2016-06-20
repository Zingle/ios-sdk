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

static const int zngLogLevel = ZNGLogLevelInfo;

@implementation ZNGMessage
{
    JSQPhotoMediaItem * photoMediaItem;
}

#pragma mark - Initialization
- (instancetype) initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    
    if (self != nil) {
        if ([self isMediaMessage]) {
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
        ZNGLogWarn(@"Unable to parse URL for message attachment: ", path);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSData * imageData = [NSData dataWithContentsOfURL:url];
        
        if (imageData == nil) {
            ZNGLogWarn(@"Unable to retrieve image data for message attachment from %@", path);
            return;
        }
        
        UIImage * image = [[UIImage alloc] initWithData:imageData];
        JSQPhotoMediaItem * mediaItem = [[JSQPhotoMediaItem alloc] initWithImage:image];
        
        if ((image == nil) || (mediaItem == nil)) {
            ZNGLogWarn(@"Unable to parse image data from %@", path);
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            photoMediaItem = mediaItem;
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

- (NSString *) senderDisplayName
{
    // TODO: Implement
    return @"TODO: a name";
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
    return photoMediaItem;
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
