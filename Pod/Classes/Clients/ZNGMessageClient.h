//
//  ZNGMessageClient.h
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGMessage.h"
#import "ZNGNewMessage.h"

@interface ZNGMessageClient : ZNGBaseClient

#pragma mark - GET methods

+ (void)messageListWithParameters:(NSDictionary*)parameters
                    withServiceId:(NSString*)serviceId
                          success:(void (^)(NSArray* messages, ZNGStatus* status))success
                          failure:(void (^)(ZNGError* error))failure;

+ (void)messageWithId:(NSString*)messageId
        withServiceId:(NSString*)serviceId
              success:(void (^)(ZNGMessage* message, ZNGStatus* status))success
              failure:(void (^)(ZNGError* error))failure;

#pragma mark - POST methods

+ (void)sendMessage:(ZNGNewMessage*)newMessage
      withServiceId:(NSString*)serviceId
            success:(void (^)(ZNGMessage* message, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure;

+ (void)markMessageReadWithId:(NSString*)messageId
                withServiceId:(NSString*)serviceId
                      success:(void (^)(ZNGMessage* message, ZNGStatus* status))success
                      failure:(void (^)(ZNGError* error))failure;

+ (void)markAllMessagesReadWithServiceId:(NSString*)serviceId
                                 success:(void (^)(ZNGStatus* status))success
                                 failure:(void (^)(ZNGError* error))failure;

+ (void)deleteMessages:(NSArray *)messageIds
         withServiceId:(NSString*)serviceId
               success:(void (^)(ZNGStatus* status))success
               failure:(void (^)(ZNGError* error))failure;

+ (void)deleteAllMessagesForContactId:(NSString *)contactId
                        withServiceId:(NSString*)serviceId
                              success:(void (^)(ZNGStatus* status))success
                              failure:(void (^)(ZNGError* error))failure;

@end
