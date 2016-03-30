//
//  ZNGConversation.m
//  Pods
//
//  Created by Ryan Farley on 2/18/16.
//
//

#import "ZNGConversation.h"
#import "ZNGMessageClient.h"
#import "ZNGServiceClient.h"

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

- (NSString *)contactChannelValue
{
    if (_contactChannelValue == nil) {
        _contactChannelValue = self.contactId;
    }
    return _contactChannelValue;
}

- (NSString *)serviceChannelValue
{
    if (_serviceChannelValue == nil) {
        _serviceChannelValue = self.serviceId;
    }
    return _serviceChannelValue;
}

- (void)updateMessages
{
    NSDictionary *params = @{kConversationPageSize : @100,
                             kConversationContactId : self.contactId,
                             kConversationPage : @1,
                             kConversationSortField : kConversationCreatedAt};
    
    [ZNGMessageClient messageListWithParameters:params withServiceId:self.serviceId success:^(NSArray *messages, ZNGStatus* status) {
        
        if ([messages count] == [self.messages count]) {
            [self.delegate messagesUpdated:NO];
            return;
        }
        self.messages = [messages mutableCopy];
        
        NSInteger pageNumbers = status.totalPages;
        
        [self.delegate messagesUpdated:YES];
        
        for (int i = 2; i <= pageNumbers; i++) {
            NSDictionary *params = @{kConversationPageSize : @100,
                                     kConversationContactId : self.contactId,
                                     kConversationPage : @(i),
                                     kConversationSortField : kConversationCreatedAt};

            [ZNGMessageClient messageListWithParameters:params withServiceId:self.serviceId success:^(NSArray *messages, ZNGStatus* status) {
                
                NSMutableArray *temp = [NSMutableArray arrayWithArray:self.messages];
                [temp addObjectsFromArray:messages];
                self.messages = temp;
                
                [self.delegate messagesUpdated:YES];
                
            } failure:nil];
        }
        
    } failure:nil];
}

- (void)sendMessageWithBody:(NSString *)body
                    success:(void (^)(ZNGStatus* status))success
                    failure:(void (^) (ZNGError *error))failure
{
    if (self.channelType == nil) {
        [ZNGServiceClient serviceWithId:self.serviceId success:^(ZNGService *service, ZNGStatus *status) {
            for (ZNGChannelType *channelType in service.channelTypes) {
                
                if ([channelType.typeClass isEqualToString:@"UserDefinedChannel"]) {
                    self.channelType = channelType;
                    ZNGNewMessage *newMessage = [self newMessageToService:self.toService forTypeClass:channelType.typeClass];
                    newMessage.body = body;
                    newMessage.channelTypeIds = @[self.channelType.channelTypeId];
                    [ZNGMessageClient sendMessage:newMessage withServiceId:self.serviceId success:^(ZNGMessage *message, ZNGStatus *status) {
                        if (success) {
                            success(status);
                        }
                    } failure:failure];
                }
            }
            if (self.channelType == nil) {
                NSLog(@"Service %@ (id=%@) does not support user defined channels. You must set the channelTypeId.", service.displayName, service.serviceId);
                failure(nil);
            }
        } failure:^(ZNGError *error) {
            NSLog(@"Service ID is required.");
            failure(error);
        }];
    } else {
        ZNGNewMessage *newMessage = [self newMessageToService:self.toService forTypeClass:self.channelType.typeClass];
        newMessage.body = body;
        newMessage.channelTypeIds = @[self.channelType.channelTypeId];
        [ZNGMessageClient sendMessage:newMessage withServiceId:self.serviceId success:^(ZNGMessage *message, ZNGStatus *status) {
            if (success) {
                success(status);
            }
        } failure:failure];
    }
}

- (void)sendMessageWithImage:(UIImage *)image
                     success:(void (^)(ZNGStatus* status))success
                     failure:(void (^) (ZNGError *error))failure
{
    UIImage *imageForUpload = [self resizeImage:image];
    
    NSData *base64Data = [UIImagePNGRepresentation(imageForUpload) base64EncodedDataWithOptions:0];
    NSString *encodedString = [[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding];
    
    if (self.channelType == nil) {
        [ZNGServiceClient serviceWithId:self.serviceId success:^(ZNGService *service, ZNGStatus *status) {
            for (ZNGChannelType *channelType in service.channelTypes) {
                
                if ([channelType.typeClass isEqualToString:@"UserDefinedChannel"]) {
                    self.channelType = channelType;
                    ZNGNewMessage *newMessage = [self newMessageToService:self.toService forTypeClass:channelType.typeClass];
                    newMessage.attachments = @[@{
                                                   kAttachementContentTypeKey : kAttachementContentTypeParam,
                                                   kAttachementBase64 : encodedString
                                                   }];
                    newMessage.channelTypeIds = @[self.channelType.channelTypeId];
                    [ZNGMessageClient sendMessage:newMessage withServiceId:self.serviceId success:^(ZNGMessage *message, ZNGStatus *status) {
                        if (success) {
                            success(status);
                        }
                    } failure:failure];
                }
            }
            if (self.channelType == nil) {
                NSLog(@"Service %@ (id=%@) does not support user defined channels. You must set the channelTypeId.", service.displayName, service.serviceId);
                failure(nil);
            }
        } failure:^(ZNGError *error) {
            NSLog(@"Service ID is required.");
            failure(error);
        }];
    } else {
        ZNGNewMessage *newMessage = [self newMessageToService:self.toService forTypeClass:self.channelType.typeClass];
        newMessage.attachments = @[@{
                                       kAttachementContentTypeKey : kAttachementContentTypeParam,
                                       kAttachementBase64 : encodedString
                                       }];
        newMessage.channelTypeIds = @[self.channelType.channelTypeId];
        [ZNGMessageClient sendMessage:newMessage withServiceId:self.serviceId success:^(ZNGMessage *message, ZNGStatus *status) {
            if (success) {
                success(status);
            }
        } failure:failure];
    }
}

- (ZNGNewMessage *)newMessageToService:(BOOL)toService forTypeClass:(NSString *)typeClass
{
    ZNGNewMessage *newMessage = [[ZNGNewMessage alloc] init];
    
    NSString *serviceChannelValue = [typeClass isEqualToString:@"UserDefinedChannel"] ? nil : self.serviceChannelValue;

    if (toService) {
        newMessage.senderType = kConversationContact;
        newMessage.sender = [ZNGParticipant participantForContactId:self.contactId withContactChannelValue:self.contactChannelValue];
        newMessage.recipientType = kConversationService;
        newMessage.recipients = @[[ZNGParticipant participantForServiceId:self.serviceId withServiceChannelValue:serviceChannelValue]];
    } else {
        newMessage.senderType = kConversationService;
        newMessage.sender = [ZNGParticipant participantForServiceId:self.serviceId withServiceChannelValue:serviceChannelValue];
        newMessage.recipientType = kConversationContact;
        newMessage.recipients = @[[ZNGParticipant participantForContactId:self.contactId withContactChannelValue:self.contactChannelValue]];
    }
    
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
