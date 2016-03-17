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

@protocol ZNGConversationDelegate <NSObject>

- (void)messagesUpdated;

@end

@interface ZNGConversation : NSObject

@property (nonatomic, strong) NSString *channelTypeId;
@property (nonatomic, strong) NSString *contactChannelValue;
@property (nonatomic, strong) ZNGContact *contact;
@property (nonatomic, strong) ZNGService *service;
@property (nonatomic) BOOL toService;
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic,weak) id<ZNGConversationDelegate> delegate;

- (void)updateMessages;

- (void)sendMessageWithBody:(NSString *)body
                    success:(void (^)(ZNGStatus* status))success
                    failure:(void (^) (ZNGError *error))failure;

- (void)sendMessageWithImage:(UIImage *)image
                     success:(void (^)(ZNGStatus* status))success
                     failure:(void (^) (ZNGError *error))failure;

- (NSString *)messageDirectionFor:(ZNGMessage *)message;

@end
