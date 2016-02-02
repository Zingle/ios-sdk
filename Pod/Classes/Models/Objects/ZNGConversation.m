//
//  ZNGConversation.m
//  ZingleSDK
//
//  Copyright © 2015 Zingle.me. All rights reserved.
//

#import "ZNGConversation.h"
#import "ZingleSDK.h"
#import "ZNGContact.h"
#import "ZNGService.h"
#import "ZNGMessageSearch.h"
#import "ZNGMessageCorrespondent.h"
#import "ZNGMessage.h"
#import "ZNGMessageAttachment.h"
#import "ZNGContactChannel.h"
#import "ZNGChannelType.h"

@interface ZNGConversation()

@end

@implementation ZNGConversation

- (id)initWithService:(ZNGService *)service usingChannelType:(ZNGChannelType *)channelType;
{
    if( self = [super init]  ) {
        self.service = service;
        self.channelType = channelType;
    }
    return self;
}

- (id)initWithChannelType:(ZNGChannelType *)channelType
{
    if( self = [super init]  ) {
        self.service = [ZingleSDK sharedSDK].currentService;
        self.channelType = channelType;
    }
    return self;
}

- (void)toCorrespondant:(ZNGMessageCorrespondent *)to
{
    if( ![[to correspondentType] isEqualToString:ZINGLE_CORRESPONDENT_TYPE_CONTACT] ) {
         [NSException raise:@"ZINGLE_SDK_INVALID_CONTACT_CORRESPONDENT" format:@"Conversations must have a recipient Contact"];
    }
    
    self.from = [[ZNGMessageCorrespondent alloc] init];
    [self.from setCorrespondent:self.service];
    
    self.to = to;
}

- (void)fromCorrespondant:(ZNGMessageCorrespondent *)from
{
    if( ![[from correspondentType] isEqualToString:ZINGLE_CORRESPONDENT_TYPE_CONTACT] ) {
        [NSException raise:@"ZINGLE_SDK_INVALID_CONTACT_CORRESPONDENT" format:@"Conversations must have a from Contact"];
    }
    
    self.to = [[ZNGMessageCorrespondent alloc] init];
    [self.to setCorrespondent:self.service];
    
    self.from = from;
}

- (BOOL)isFromService
{
    if( self.from != nil ) {
        return [[self.from correspondentType] isEqualToString:ZINGLE_CORRESPONDENT_TYPE_SERVICE];
    }
    
    return NO;
}

- (ZNGMessageCorrespondent *)contactCorrespondent
{
    if( [self isFromService] ) {
        return self.to;
    }
    
    return self.from;
}

- (NSString *)messageDirectionFor:(ZNGMessage *)message
{
    NSString *direction = message.direction;
    if( ![self isFromService] ) {
        direction = ([direction isEqualToString:@"outbound"]) ? @"inbound" : @"outbound";
    }
    
    return direction;
}

- (NSString *)contactChannelID
{
    ZNGMessageCorrespondent *contactCorrespondent = [self contactCorrespondent];
    NSString *channelValue = contactCorrespondent.channelValue;
    
    ZNGContact *contact;
    if( contactCorrespondent.correspondent != nil ) {
        contact = (ZNGContact *)contactCorrespondent.correspondent;
    } else {
        contact = [self.service findOrCreateContactWithChannelTypeID:self.channelType.ID andChannelValue:channelValue error:nil];
    }
    
    for( ZNGContactChannel *channel in contact.channels ) {
        if( //[channel.channelType.ID isEqualToString:self.channelType.ID] &&
           [channel.value isEqualToString:channelValue] ) {
            return channel.ID;
        }
    }
    
    return nil;
}

- (NSArray *)messages
{
    ZNGMessageSearch *messageSearch = [[ZNGMessageSearch alloc] initWithService:self.service];
    messageSearch.contactChannelId = [self contactChannelID];
    [messageSearch setPageSize:100];
    return [messageSearch searchWithError:nil];
}

- (ZNGMessage *)prepareMessageWithBody:(NSString *)body andImage:(UIImage *)image
{
    ZNGMessage *newMessage = [[ZNGMessage alloc] initWithService:self.service];
    newMessage.sender = self.from;
    [newMessage setRecipient:self.to];
    newMessage.body = body;
    [newMessage addChannelType:self.channelType];
    
    if( image != nil ) {
        ZNGMessageAttachment *attachment = [newMessage newAttachment];
        [attachment setImage:image];
    }
    
    return newMessage;
}

- (ZNGMessage *)sendMessageWithBody:(NSString *)body error:(NSError **)error
{
    ZNGMessage *newMessage = [self prepareMessageWithBody:body andImage:nil];
    [newMessage saveWithError:error];
    return nil;
}

- (ZNGMessage *)sendMessageWithImage:(UIImage *)image error:(NSError **)error
{
    ZNGMessage *newMessage = [self prepareMessageWithBody:@"" andImage:image];
    [newMessage saveWithError:error];
    return nil;
}

- (void)sendMessageWithBody:(NSString *)body
            completionBlock:(void (^) (void))completionBlock
                 errorBlock:(void (^) (NSError *error))errorBlock
{
    ZNGMessage *newMessage = [self prepareMessageWithBody:body andImage:nil];
    [newMessage saveWithCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock();
        });
    } errorBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}

- (void)sendMessageWithImage:(UIImage *)image
             completionBlock:(void (^) (void))completionBlock
                  errorBlock:(void (^) (NSError *error))errorBlock
{
    ZNGMessage *newMessage = [self prepareMessageWithBody:@"" andImage:image];
    [newMessage saveWithCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock();
        });
    } errorBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}


@end
