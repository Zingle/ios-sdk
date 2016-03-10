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
        
        if ([messages count] == [self.messages count]) {
            return;
        }
        self.messages = [messages mutableCopy];
        
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
                    success:(void (^)(ZNGStatus* status))success
                    failure:(void (^) (ZNGError *error))failure
{
    ZNGNewMessage *newMessage = [self newMessageToService:self.toService];
    newMessage.body = body;
    [ZNGMessageClient sendMessage:newMessage withServiceId:self.service.participantId success:^(ZNGMessage *message, ZNGStatus *status) {
        if (success) {
            success(status);
        }
    } failure:failure];
}

- (void)sendMessageWithImage:(UIImage *)image
                     success:(void (^)(ZNGStatus* status))success
                     failure:(void (^) (ZNGError *error))failure
{
    ZNGNewMessage *newMessage = [self newMessageToService:self.toService];
    
    UIImage *imageForUpload = [self resizeImage:image];
    
    NSData *base64Data = [UIImagePNGRepresentation(imageForUpload) base64EncodedDataWithOptions:0];
    NSString *encodedString = [[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding];
    
    newMessage.attachments = @[@{
                                   kAttachementContentTypeKey : kAttachementContentTypeParam,
                                   kAttachementBase64 : encodedString
                                }];
    
    [ZNGMessageClient sendMessage:newMessage withServiceId:self.service.participantId success:^(ZNGMessage *message, ZNGStatus *status) {
        if (success) {
            success(status);
        }
    } failure:failure];
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

-(UIImage *)resizeImage:(UIImage *)image
{
    float actualHeight = image.size.height;
    float actualWidth = image.size.width;
    float maxHeight = 800.0;
    float maxWidth = 800.0;
    float imgRatio = actualWidth/actualHeight;
    float maxRatio = maxWidth/maxHeight;
    float compressionQuality = 0.5;//50 percent compression
    
    if (actualHeight > maxHeight || actualWidth > maxWidth)
    {
        if(imgRatio < maxRatio)
        {
            //adjust width according to maxHeight
            imgRatio = maxHeight / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = maxHeight;
        }
        else if(imgRatio > maxRatio)
        {
            //adjust height according to maxWidth
            imgRatio = maxWidth / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = maxWidth;
        }
        else
        {
            actualHeight = maxHeight;
            actualWidth = maxWidth;
        }
    }
    
    CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    NSData *imageData = UIImageJPEGRepresentation(img, compressionQuality);
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithData:imageData];
    
}

@end
