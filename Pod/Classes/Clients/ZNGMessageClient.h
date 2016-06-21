//
//  ZNGMessageClient.h
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import "ZNGBaseClientService.h"
#import "ZNGMessage.h"
#import "ZNGNewMessage.h"

@interface ZNGMessageClient : ZNGBaseClientService

#pragma mark - GET methods

- (void)messageListWithParameters:(NSDictionary*)parameters
                          success:(void (^)(NSArray* messages, ZNGStatus* status))success
                          failure:(void (^)(ZNGError* error))failure;

- (void)messageWithId:(NSString*)messageId
              success:(void (^)(ZNGMessage* message, ZNGStatus* status))success
              failure:(void (^)(ZNGError* error))failure;

#pragma mark - POST methods

- (void)sendMessage:(ZNGNewMessage*)newMessage
            success:(void (^)(ZNGNewMessageResponse * message, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure;

- (void)markMessageReadWithId:(NSString*)messageId
                       readAt:(NSDate *)readAt
                      success:(void (^)(ZNGMessage* message, ZNGStatus* status))success
                      failure:(void (^)(ZNGError* error))failure;

- (void)markMessagesReadWithMessageIds:(NSArray *)messageIds
                                readAt:(NSDate *)readAt
                               success:(void (^)(ZNGStatus* status))success
                               failure:(void (^)(ZNGError* error))failure;

- (void)markAllMessagesReadWithReadAt:(NSDate *)readAt
                              success:(void (^)(ZNGStatus* status))success
                              failure:(void (^)(ZNGError* error))failure;

- (void)deleteMessages:(NSArray *)messageIds
               success:(void (^)(ZNGStatus* status))success
               failure:(void (^)(ZNGError* error))failure;

- (void)deleteAllMessagesForContactId:(NSString *)contactId
                              success:(void (^)(ZNGStatus* status))success
                              failure:(void (^)(ZNGError* error))failure;

@end
