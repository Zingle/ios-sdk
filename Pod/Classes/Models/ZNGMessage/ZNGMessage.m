//
//  ZNGMessage.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGMessage.h"
#import "ZingleValueTransformers.h"
#import "JSQPhotoMediaItem.h"
#import "JSQMessagesMediaPlaceholderView.h"
#import "ZNGImageAttachment.h"
#import "UIColor+ZingleSDK.h"
#import "ZNGImageSizeCache.h"
#import "ZNGPlaceholderImageAttachment.h"
#import <ImageIO/ImageIO.h>
#import "UIImage+animatedGIF.h"

@implementation ZNGMessage
{
    NSAttributedString * attributedText;
    NSUInteger numLoadedImagesInAttributedText;
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

- (NSString *) senderPersonId
{
    if (![self isOutbound]) {
        return self.sender.correspondentId;
    }
    
    return self.triggeredByUser.userId;
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
             NSStringFromSelector(@selector(outgoingImageAttachments)) : [NSNull null],
             NSStringFromSelector(@selector(forwardedByServiceId)) : @"forwarded_by_service_id"
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
