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
#import "ZNGMessageStatus.h"

NSUInteger const ZNGMessageMaximumCharacterLength = 1600;

@implementation ZNGMessage
{
    NSAttributedString * attributedText;
    NSUInteger numLoadedImagesInAttributedText;
}

+ (NSValueTransformer *) bodyJSONTransformer
{
    return [MTLValueTransformer transformerUsingReversibleBlock:^id(NSString * source, BOOL *success, NSError *__autoreleasing *error) {
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

- (BOOL) failed
{
    for (ZNGMessageStatus * status in self.statuses) {
        if ([status isFailure]) {
            return YES;
        }
    }
    
    return NO;
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

- (BOOL) hasChangedSince:(ZNGMessage *)oldMessage
{
    return (self.isDelayed != oldMessage.isDelayed);
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
             @"triggeredByUser" : @"triggered_by_user",
             @"templateId" : @"template_id",
             @"senderType" : @"sender_type",
             @"sender" : @"sender",
             @"recipientType" : @"recipient_type",
             @"recipient" : @"recipient",
             @"attachments" : @"attachments",
             @"createdAt" : @"created_at",
             @"readAt" : @"read_at",
             NSStringFromSelector(@selector(forwardedByServiceId)) : @"forwarded_by_service_id",
             NSStringFromSelector(@selector(isDelayed)) : @"is_delayed",
             NSStringFromSelector(@selector(executeAt)) : @"execute_at",
             NSStringFromSelector(@selector(executedAt)) : @"executed_at",
             NSStringFromSelector(@selector(statuses)): @"statuses",
             };
}

+ (NSValueTransformer*)senderJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ZNGCorrespondent class]];
}

+ (NSValueTransformer*)recipientJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ZNGCorrespondent class]];
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
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ZNGUser class]];
}

+ (NSValueTransformer *)executeAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer *)executedAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer *)statusesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGMessageStatus class]];
}

@end
