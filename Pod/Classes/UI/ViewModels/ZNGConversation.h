//
//  ZNGConversation.h
//  Pods
//
//  Created by Ryan Farley on 2/18/16.
//
//

#import <Foundation/Foundation.h>
#import "ZNGStatus.h"
#import "ZNGMessage.h"
#import "ZNGError.h"
#import "ZNGContact.h"
#import "ZNGService.h"

@class ZNGMessage;
@class ZingleSession;

@protocol ZNGConversationDelegate <NSObject>

- (void)messagesUpdated:(BOOL)newMessages;
- (void)messagesMarkedAsRead:(BOOL)success;

@end

@interface ZNGConversation : NSObject

@property (nonatomic, weak) ZingleSession * session;

@property (nonatomic, strong) ZNGChannelType *channelType;
@property (nonatomic, strong) NSString *contactChannelValue;
@property (nonatomic, strong) NSString *serviceChannelValue;
@property (nonatomic, strong) NSString *serviceId;
@property (nonatomic, strong) NSString *contactId;

@property (nonatomic) BOOL toService;
@property (nonatomic, strong) NSMutableArray<ZNGMessage *> *messages;
@property (nonatomic,weak) id<ZNGConversationDelegate> delegate;

- (void)updateMessages;
- (void)markMessagesAsRead;

- (void)sendMessageWithBody:(NSString *)body
                    success:(void (^)(ZNGStatus* status))success
                    failure:(void (^) (ZNGError *error))failure;

- (void)sendMessageWithImage:(UIImage *)image
                     success:(void (^)(ZNGStatus* status))success
                     failure:(void (^) (ZNGError *error))failure;

- (NSString *)messageDirectionFor:(ZNGMessage *)message;

@end
