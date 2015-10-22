//
//  ZNGMessage.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZingleModel.h"

@class ZNGMessageCorrespondent;
@class ZNGChannelType;
@class ZNGService;
@class ZNGMessageAttachment;

@interface ZNGMessage : ZingleModel

@property (nonatomic, retain) ZNGService *service;
@property (nonatomic, retain) NSString *body;
@property (nonatomic, retain) ZNGMessageCorrespondent *sender;
@property (nonatomic, retain) NSMutableArray *recipients, *attachments, *channelTypes;
@property (nonatomic, retain) NSDate *readAt;
@property (nonatomic) BOOL isRead;

//{
////    "body": "Test escalation",
////    "id": "2a81d959-3a57-4ebb-a5b6-655c03cb84d8",
//    "created_at": 1385574098,
////    "read_at": null,
//    "contact_channel": {
//        "type_class": null,
//        "display_name": null,
//        "value": null,
//        "formatted_value": null
//    },
//    "service_channel": {
//        "type_class": null,
//        "display_name": null,
//        "value": null,
//        "formatted_value": null
//    },
//    "template_id": null,
//    "communication_direction": "inbound",
//    "contact_id": 9931,
//    "body_language_code": null,
//    "translated_body_language_code": null,
//    "triggered_by_user_id": null,
//    "translated_body": null,
//    "automation_parsed_body": null
//}

- (id)initWithService:(ZNGService *)service;
- (ZNGMessageCorrespondent *)newRecipient;
- (ZNGMessageAttachment *)newAttachment;
- (void)addChannelType:(ZNGChannelType *)channelType;
- (void)setChannelType:(ZNGChannelType *)channelType;

- (void)addRecipient:(ZNGMessageCorrespondent *)recipient;
- (void)setRecipient:(ZNGMessageCorrespondent *)recipient;
- (void)clearRecipients;
- (void)clearAttchments;
- (void)clearChannelTypes;

- (BOOL)sendWithError:(NSError **)error;
- (void)sendWithCompletionBlock:(void (^) (void))completionBlock
errorBlock:(void (^) (NSError *error))errorBlock;


- (BOOL)markAsReadNowWithError:(NSError **)error;
- (BOOL)markAsReadAt:(NSDate *)readAt withError:(NSError **)error;
- (void)markAsReadNowWithCompletionBlock:(void (^) (void))completionBlock
                              errorBlock:(void (^) (NSError *error))errorBlock;
- (void)markAsReadAt:(NSDate *)readAt
 withCompletionBlock:(void (^) (void))completionBlock
          errorBlock:(void (^) (NSError *error))errorBlock;

@end
