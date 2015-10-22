//
//  ZNGMessage.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGMessage.h"
#import "ZingleModel.h"
#import "ZNGChannelType.h"
#import "ZNGService.h"
#import "ZNGMessageCorrespondent.h"
#import "ZNGMessageAttachment.h"
#import "ZingleSDK.h"
#import "ZingleDAO.h"
#import "ZingleDAOResponse.h"

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

- (void)preSaveValidation
{
    if( ![self isNew] )
    {
        [NSException raise:@"ZINGLE_CANNOT_RESEND" format:@"Cannot resend an existing communication."];
    }
    
    if( self.service == nil )
    {
        [NSException raise:@"ZINGLE_SERVICE_MISSING_SERVICE" format:@"Missing service."];
    }
    if( self.sender == nil )
    {
        [NSException raise:@"ZINGLE_SERVICE_MISSING_SENDER" format:@"Missing sender."];
    }
    if( [self.recipients count] == 0 )
    {
        [NSException raise:@"ZINGLE_SERVICE_MISSING_RECIPIENTS" format:@"No recipients."];
    }
    if( self.body == nil || [self.body length] == 0 )
    {
        [NSException raise:@"ZINGLE_SERVICE_MISSING_BODY" format:@"Please supply a body"];
    }
}

- (BOOL)sendWithError:(NSError **)error
{
    return [self saveWithError:error];
}

- (void)sendWithCompletionBlock:(void (^) (void))completionBlock
                     errorBlock:(void (^) (NSError *error))errorBlock
{
    [self saveWithCompletionBlock:^{
        completionBlock();
    } errorBlock:^(NSError *error) {
        errorBlock(error);
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
        completionBlock();
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)markAsReadAt:(NSDate *)readAt
 withCompletionBlock:(void (^) (void))completionBlock
          errorBlock:(void (^) (NSError *error))errorBlock
{
    [self prepareMarkRead];
    [self.DAO setPostVar:[NSNumber numberWithInt:[readAt timeIntervalSince1970]] forKey:@"read_at"];
    
    [self markReadAsyncWithCompletionBlock:^{
        completionBlock();
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)markReadAsyncWithCompletionBlock:(void (^) (void))completionBlock
                              errorBlock:(void (^) (NSError *error))errorBlock
{
    [self.DAO sendAsynchronousRequestTo:[self baseURIWithID:YES]
                        completionBlock:^(ZingleDAOResponse *response) {
                            if( [response successful] ) {
                                [self hydrate:[response result]];
                            } else {
                                // Error
                            }
                            completionBlock();
                        } errorBlock:^(ZingleDAOResponse *response, NSError *error) {
                            errorBlock(error);
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
    
    [dictionary setObject:[self.sender asDictionary] forKey:@"sender"];
    
    NSMutableArray *recipients = [NSMutableArray array];
    for( ZNGMessageCorrespondent *recipient in self.recipients )
    {
        [recipients addObject:[recipient asDictionary]];
    }
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
    description = [description stringByAppendingFormat:@"    readAt: %@\r", self.readAt];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}

@end
