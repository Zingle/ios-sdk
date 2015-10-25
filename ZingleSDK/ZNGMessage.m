//
//  ZNGMessage.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGMessage.h"
#import "NSMutableDictionary+json.h"
#import "ZingleModel.h"
#import "ZNGChannelType.h"
#import "ZNGService.h"
#import "ZNGMessageCorrespondent.h"
#import "ZNGMessageAttachment.h"
#import "ZingleSDK.h"
#import "ZingleDAO.h"
#import "ZingleDAOResponse.h"
#import "ZNGContact.h"
#import "ZNGLabel.h"

@implementation ZNGMessage

- (id)initWithService:(ZNGService *)service
{
    if( self = [super init] )
    {
        self.service = service;
        self.sender = [[ZNGMessageCorrespondent alloc] init];
        [self clearRecipients];
        [self clearAttchments];
        [self clearChannelTypes];
    }
    return self;
}

- (NSString *)baseURIWithID:(BOOL)withID
{
    if( withID ) {
        return [NSString stringWithFormat:@"services/%@/messages/%@", self.service.ID, self.ID];
    } else {
        return [NSString stringWithFormat:@"services/%@/messages", self.service.ID];
    }
}

- (void)hydrateDates:(NSMutableDictionary *)data
{
    [super hydrateDates:data];
    
    NSNumber *readAt = [data objectAtPath:@"read_at" expectedClass:[NSNumber class] default:nil];\
    
    self.readAt = nil;
    if( readAt != nil )
    {
        self.readAt = [[NSDate alloc] initWithTimeIntervalSince1970:[readAt intValue]];
    }
}

- (void)hydrate:(NSMutableDictionary *)data
{
    [self hydrateDates:data];
    
    self.ID = [data objectAtPath:@"id" expectedClass:[NSString class] default:nil];
    self.body = [data objectAtPath:@"body" expectedClass:[NSString class] default:@""];
    self.bodyLanguageCode = [data objectAtPath:@"body_language_code" expectedClass:[NSString class] default:nil];
    self.translatedBody = [data objectAtPath:@"translated_body" expectedClass:[NSString class] default:nil];
    self.translatedBodyLanguageCode = [data objectAtPath:@"translated_body_language_code" expectedClass:[NSString class] default:nil];
    
    self.templateID = [data objectAtPath:@"template_id" expectedClass:[NSString class] default:nil];
    self.direction = [data objectAtPath:@"communication_direction" expectedClass:[NSString class] default:@""];
    
    
    NSString *senderType = [data objectAtPath:@"sender_type" expectedClass:[NSString class] default:@""];
    NSString *senderID = [data objectAtPath:@"sender.id" expectedClass:[NSString class] default:@""];
    ZingleModel *senderModel = [self buildModelForType:senderType withID:senderID];
    
    NSString *recipientType = [data objectAtPath:@"recipient_type" expectedClass:[NSString class] default:@""];
    NSString *recipientID = [data objectAtPath:@"recipient.id" expectedClass:[NSString class] default:@""];
    ZingleModel *recipientModel = [self buildModelForType:recipientType withID:recipientID];
    
    ZNGService *masterService;
    if( ([senderType isEqualToString:ZINGLE_CORRESPONDENT_TYPE_SERVICE] &&
        ![recipientType isEqualToString:ZINGLE_CORRESPONDENT_TYPE_SERVICE]) )
    {
        masterService = (ZNGService *)senderModel;
    } else if( (![senderType isEqualToString:ZINGLE_CORRESPONDENT_TYPE_SERVICE] &&
                [recipientType isEqualToString:ZINGLE_CORRESPONDENT_TYPE_SERVICE]) ) {
        masterService = (ZNGService *)recipientModel;
    }
    
    self.service = masterService;
    
    self.sender = [[ZNGMessageCorrespondent alloc] init];
    [self.sender setCorrespondent:senderModel];
    self.sender.channelValue = [data objectAtPath:@"sender.channel.value" expectedClass:[NSString class] default:@""];
    self.sender.formattedChannelValue = [data objectAtPath:@"sender.channel.formatted_value" expectedClass:[NSString class] default:@""];

    ZNGMessageCorrespondent *recipient = [[ZNGMessageCorrespondent alloc] init];
    [recipient setCorrespondent:recipientModel];
    recipient.channelValue = [data objectAtPath:@"recipient.channel.value" expectedClass:[NSString class] default:@""];
    recipient.formattedChannelValue = [data objectAtPath:@"recipient.channel.formatted_value" expectedClass:[NSString class] default:@""];
    
    self.recipients = [NSMutableArray arrayWithObjects:recipient, nil];
    
    self.attachments = [NSMutableArray array];
    
    NSMutableArray *attachmentData = [data objectAtPath:@"attachments" expectedClass:[NSArray class] default:[NSMutableArray array]];
    
    for( NSString *attachmentUrl in attachmentData ) {
        ZNGMessageAttachment *attachment = [[ZNGMessageAttachment alloc] init];
        attachment.url = attachmentUrl;
        [self.attachments addObject:attachment];
    }
}

- (ZingleModel *)buildModelForType:(NSString *)type withID:(NSString *)ID
{
    ZingleModel *model;
    if( [type isEqualToString:ZINGLE_CORRESPONDENT_TYPE_CONTACT] ) {
        model = [[ZNGContact alloc] init];
    } else if( [type isEqualToString:ZINGLE_CORRESPONDENT_TYPE_SERVICE] ) {
        model = [[ZNGService alloc] init];
    } else if( [type isEqualToString:ZINGLE_CORRESPONDENT_TYPE_LABEL] ) {
        model = [[ZNGLabel alloc] init];
    }
    
    model.ID = ID;
    
    return model;
}

- (ZNGMessageCorrespondent *)newRecipient
{
    ZNGMessageCorrespondent *recipient = [[ZNGMessageCorrespondent alloc] init];
    [self.recipients addObject:recipient];
    return recipient;
}

- (ZNGMessageAttachment *)newAttachment
{
    ZNGMessageAttachment *attachment = [[ZNGMessageAttachment alloc] init];
    [self.attachments addObject:attachment];
    return attachment;
}

- (void)addChannelType:(ZNGChannelType *)channelType
{
    [self.channelTypes addObject:channelType];
}

- (void)setChannelType:(ZNGChannelType *)channelType
{
    self.channelTypes = [NSMutableArray arrayWithObject:channelType];
}

- (void)addRecipient:(ZNGMessageCorrespondent *)recipient
{
    if( ![self.recipients containsObject:recipient] ) {
        [self.recipients addObject:recipient];
    }
}

- (void)setRecipient:(ZNGMessageCorrespondent *)recipient
{
    self.recipients = [NSMutableArray arrayWithObject:recipient];
}

- (void)clearRecipients
{
    self.recipients = [NSMutableArray array];
}

- (void)clearAttchments
{
    self.attachments = [NSMutableArray array];
}

- (void)clearChannelTypes
{
    self.channelTypes = [NSMutableArray array];
}

- (NSError *)preSaveValidation
{
    return nil;
//    if( ![self isNew] )
//    {
//        [NSException raise:@"ZINGLE_CANNOT_RESEND" format:@"Cannot resend an existing communication."];
//    }
//    
//    if( self.service == nil )
//    {
//        [NSException raise:@"ZINGLE_SERVICE_MISSING_SERVICE" format:@"Missing service."];
//    }
//    if( self.sender == nil )
//    {
//        [NSException raise:@"ZINGLE_SERVICE_MISSING_SENDER" format:@"Missing sender."];
//    }
//    if( [self.recipients count] == 0 )
//    {
//        [NSException raise:@"ZINGLE_SERVICE_MISSING_RECIPIENTS" format:@"No recipients."];
//    }
//    if( self.body == nil || [self.body length] == 0 )
//    {
//        [NSException raise:@"ZINGLE_SERVICE_MISSING_BODY" format:@"Please supply a body"];
//    }
}

- (BOOL)sendWithError:(NSError **)error
{
    return [self saveWithError:error];
}

- (void)sendWithCompletionBlock:(void (^) (void))completionBlock
                     errorBlock:(void (^) (NSError *error))errorBlock
{
    [self saveWithCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock();
        });
    } errorBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}

- (void)prepareMarkRead
{
    if( [self isNew] )
    {
        [NSException raise:@"ZINGLE_CANNOT_MARK_MESSAGE_READ" format:@"Message not yet saved."];
    }
    [self.DAO resetDefaults];
    [self.DAO setRequestMethod:ZINGLE_REQUEST_METHOD_POST];
}

- (BOOL)markAsReadNowWithError:(NSError **)error
{
    [self prepareMarkRead];
    return [self markReadSyncWithError:error];
}

- (BOOL)markAsReadAt:(NSDate *)readAt withError:(NSError **)error
{
    [self prepareMarkRead];
    [self.DAO setPostVar:[NSNumber numberWithInt:[readAt timeIntervalSince1970]] forKey:@"read_at"];
    return [self markReadSyncWithError:error];
}

- (BOOL)markReadSyncWithError:(NSError **)error
{
    ZingleDAOResponse *response = [self.DAO sendSynchronousRequestTo:[self baseURIWithID:YES] error:error];
    
    if( [response successful] ) {
        [self hydrate:[response result]];
        return YES;
    } else {
        return NO;
    }
}

- (void)markAsReadNowWithCompletionBlock:(void (^) (void))completionBlock
                              errorBlock:(void (^) (NSError *error))errorBlock
{
    [self prepareMarkRead];
    
    [self markReadAsyncWithCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock();
        });
    } errorBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}

- (void)markAsReadAt:(NSDate *)readAt
 withCompletionBlock:(void (^) (void))completionBlock
          errorBlock:(void (^) (NSError *error))errorBlock
{
    [self prepareMarkRead];
    [self.DAO setPostVar:[NSNumber numberWithInt:[readAt timeIntervalSince1970]] forKey:@"read_at"];
    
    [self markReadAsyncWithCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock();
        });
    } errorBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}

- (void)markReadAsyncWithCompletionBlock:(void (^) (void))completionBlock
                              errorBlock:(void (^) (NSError *error))errorBlock
{
    [self.DAO sendAsynchronousRequestTo:[self baseURIWithID:YES]
                        completionBlock:^(ZingleDAOResponse *response) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if( [response successful] ) {
                                    [self hydrate:[response result]];
                                } else {
                                    // Error
                                }
                                completionBlock();
                            });
                        } errorBlock:^(ZingleDAOResponse *response, NSError *error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                errorBlock(error);
                            });
                        }];
}

- (NSMutableDictionary *)asDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    NSMutableArray *channelTypeIDs = [NSMutableArray array];
    for( ZNGChannelType *channelType in self.channelTypes )
    {
        [channelTypeIDs addObject:channelType.ID];
    }
    [dictionary setObject:channelTypeIDs forKey:@"channel_type_ids"];
    
    [dictionary setObject:self.sender.correspondentType forKey:@"sender_type"];
    [dictionary setObject:[self.sender asDictionary] forKey:@"sender"];
    
    NSMutableArray *recipients = [NSMutableArray array];
    NSString *recipientType;
    for( ZNGMessageCorrespondent *recipient in self.recipients )
    {
        recipientType = recipient.correspondentType;
        [recipients addObject:[recipient asDictionary]];
    }
    
    [dictionary setObject:recipientType forKey:@"recipient_type"];
    [dictionary setObject:recipients forKey:@"recipients"];
    
    [dictionary setObject:self.body forKey:@"body"];
    
    NSMutableArray *attachments = [NSMutableArray array];
    for( ZNGMessageAttachment *attachment in self.attachments )
    {
        [attachments addObject:[attachment asDictionary]];
    }
    [dictionary setObject:attachments forKey:@"attachments"];
    
    return dictionary;
}

- (NSString *)description
{
    NSString *description = @"<ZNGMessage> {\r";
    description = [description stringByAppendingFormat:@"    ID: %@\r", self.ID];
    description = [description stringByAppendingFormat:@"    sender: %@\r", self.sender];
    description = [description stringByAppendingFormat:@"    recipients: %@\r", self.recipients];
    description = [description stringByAppendingFormat:@"    attachments: %@\r", self.attachments];
    description = [description stringByAppendingFormat:@"    body: %@\r", self.body];
    description = [description stringByAppendingFormat:@"    bodyLanguageCode: %@\r", self.bodyLanguageCode];
    description = [description stringByAppendingFormat:@"    translatedBody: %@\r", self.translatedBody];
    description = [description stringByAppendingFormat:@"    translatedBodyLanguageCode: %@\r", self.translatedBodyLanguageCode];
    description = [description stringByAppendingFormat:@"    templateID: %@\r", self.templateID];
    description = [description stringByAppendingFormat:@"    direction: %@\r", self.direction];
    description = [description stringByAppendingFormat:@"    readAt: %@\r", self.readAt];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}

@end
