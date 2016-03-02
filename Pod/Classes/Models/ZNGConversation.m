//
//  ZNGConversation.m
//  Pods
//
//  Created by Ryan Farley on 2/18/16.
//
//

#import "ZNGConversation.h"
#import "ZNGMessageClient.h"

@implementation ZNGConversation

NSString *const kConversationPage = @"page";
NSString *const kConversationPageSize = @"page_size";
NSString *const kConversationContactId = @"contact_id";
NSString *const kConversationSortField = @"sort_field";
NSString *const kConversationCreatedAt = @"created_at";
NSString *const kAttachementContentTypeKey = @"content_type";
NSString *const kAttachementContentTypeParam = @"image/png";
NSString *const kAttachementBase64 = @"base64";
NSString *const kConversationService = @"service";
NSString *const kConversationContact = @"contact";
NSString *const kMessageDirectionInbound = @"inbound";
NSString *const kMessageDirectionOutbound = @"outbound";

- (void)updateMessages
{
    NSDictionary *params = @{kConversationPageSize : @100,
                             kConversationContactId : self.contact.participantId,
                             kConversationPage : @1,
                             kConversationSortField : kConversationCreatedAt};
    
    [ZNGMessageClient messageListWithParameters:params withServiceId:self.service.participantId success:^(NSArray *messages, ZNGStatus* status) {
        
        self.messages = messages;
        
        NSInteger pageNumbers = status.totalPages;
        
        [self.delegate messagesUpdated];
        
        for (int i = 2; i <= pageNumbers; i++) {
            NSDictionary *params = @{kConversationPageSize : @100,
                                     kConversationContactId : self.contact.participantId,
                                     kConversationPage : @(i),
                                     kConversationSortField : kConversationCreatedAt};

            [ZNGMessageClient messageListWithParameters:params withServiceId:self.service.participantId success:^(NSArray *messages, ZNGStatus* status) {
                
                NSMutableArray *temp = [NSMutableArray arrayWithArray:self.messages];
                [temp addObjectsFromArray:messages];
                self.messages = temp;
                
                [self.delegate messagesUpdated];
                
            } failure:nil];
        }
        
    } failure:nil];
}

- (void)sendMessageWithBody:(NSString *)body
                    success:(void (^)(ZNGMessage* message, ZNGStatus* status))success
                    failure:(void (^) (ZNGError *error))failure
{
    ZNGNewMessage *newMessage = [self newMessageToService:self.toService];
    newMessage.body = body;
    [ZNGMessageClient sendMessage:newMessage withServiceId:self.service.participantId success:success failure:failure];
}

- (void)sendMessageWithImage:(UIImage *)image
                     success:(void (^)(ZNGMessage* message, ZNGStatus* status))success
                     failure:(void (^) (ZNGError *error))failure
{
    ZNGNewMessage *newMessage = [self newMessageToService:self.toService];
    
    NSData *base64Data = [UIImagePNGRepresentation(image) base64EncodedDataWithOptions:0];
    NSString *encodedString = [[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding];
    
    newMessage.attachments = @[@{
                                   kAttachementContentTypeKey : kAttachementContentTypeParam,
                                   kAttachementBase64 : encodedString
                                }];
    
    [ZNGMessageClient sendMessage:newMessage withServiceId:self.service.participantId success:success failure:failure];
}

- (ZNGNewMessage *)newMessageToService:(BOOL)toService
{
    ZNGNewMessage *newMessage = [[ZNGNewMessage alloc] init];
    
    if (toService) {
        newMessage.senderType = kConversationContact;
        newMessage.sender = self.contact;
        newMessage.recipientType = kConversationService;
        newMessage.recipients = @[self.service];
    } else {
        newMessage.senderType = kConversationService;
        newMessage.sender = self.service;
        newMessage.recipientType = kConversationContact;
        newMessage.recipients = @[self.contact];
    }
    
    newMessage.channelTypeIds = @[self.channelTypeId];
    
    return newMessage;
}

- (NSString *)messageDirectionFor:(ZNGMessage *)message
{
    NSString *direction = message.communicationDirection;
    if( self.toService ) {
        direction = ([direction isEqualToString:kMessageDirectionOutbound]) ? kMessageDirectionInbound : kMessageDirectionOutbound;
    }
    
    return direction;
}

@end
