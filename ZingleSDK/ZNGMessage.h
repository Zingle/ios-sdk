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
@property (nonatomic, retain) NSString *body, *bodyLanguageCode, *translatedBody, *translatedBodyLanguageCode, *templateID, *direction;
@property (nonatomic, retain) ZNGMessageCorrespondent *sender;
@property (nonatomic, retain) NSMutableArray *recipients, *attachments, *channelTypes;
@property (nonatomic, retain) NSDate *readAt;
@property (nonatomic) BOOL isRead;

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
