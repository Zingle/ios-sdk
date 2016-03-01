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

- (void)updateMessages
{
    NSDictionary *params = @{@"page_size" : @100,
                             @"contact_id" : self.contact.participantId,
                             @"page" : @1,
                             @"sort_field" : @"created_at"};
    
    [ZNGMessageClient messageListWithParameters:params withServiceId:self.service.participantId success:^(NSArray *messages, ZNGStatus* status) {
        
        self.messages = messages;
        
        int pageNumbers = status.totalPages;
        
        [self.delegate messagesUpdated];
        
        for (int i = 2; i <= pageNumbers; i++) {
            NSDictionary *params = @{@"page_size" : @100,
                                     @"contact_id" : self.contact.participantId,
                                     @"page" : @(i),
                                     @"sort_field" : @"created_at"};

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
    ZNGNewMessage *newMessage = [[ZNGNewMessage alloc] init];
    newMessage.senderType = @"service";
    newMessage.sender = self.service;
    newMessage.recipientType = @"contact";
    newMessage.recipients = @[self.contact];
    newMessage.channelTypeIds = @[self.channelTypeId];
    newMessage.body = body;
    
    [ZNGMessageClient sendMessage:newMessage withServiceId:self.service.participantId success:success failure:failure];
}

- (void)sendMessageWithImage:(UIImage *)image
                     success:(void (^)(ZNGMessage* message, ZNGStatus* status))success
                     failure:(void (^) (ZNGError *error))failure
{
    ZNGNewMessage *newMessage = [[ZNGNewMessage alloc] init];
    newMessage.senderType = @"service";
    newMessage.sender = self.service;
    newMessage.recipientType = @"contact";
    newMessage.recipients = @[self.contact];
    newMessage.channelTypeIds = @[self.channelTypeId];
    
    NSData *base64Data = [UIImagePNGRepresentation(image) base64EncodedDataWithOptions:0];
    NSString *encodedString = [[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding];
    
    newMessage.attachments = @[@{
                                   @"content_type" : @"image/png",
                                   @"base64" : encodedString
                                }];
    
    [ZNGMessageClient sendMessage:newMessage withServiceId:self.service.participantId success:success failure:failure];
}

@end
