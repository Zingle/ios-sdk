//
//  ZNGMessageClient.m
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import "ZNGMessageClient.h"
#import "ZNGMessageRead.h"

@implementation ZNGMessageClient

#pragma mark - GET methods

+ (void)messageListWithParameters:(NSDictionary*)parameters
                    withServiceId:(NSString*)serviceId
                          success:(void (^)(NSArray* messages, ZNGStatus* status))success
                          failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/messages", serviceId];
    
    [self getListWithParameters:parameters
                           path:path
                  responseClass:[ZNGMessage class]
                        success:success
                        failure:failure];
}

+ (void)messageWithId:(NSString*)messageId
        withServiceId:(NSString*)serviceId
              success:(void (^)(ZNGMessage* message, ZNGStatus* status))success
              failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/messages/%@", serviceId, messageId];
    
    [self getWithResourcePath:path
                responseClass:[ZNGMessage class]
                      success:success
                      failure:failure];
}

#pragma mark - POST methods

+ (void)sendMessage:(ZNGNewMessage*)newMessage
      withServiceId:(NSString*)serviceId
            success:(void (^)(ZNGMessage* message, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure
{
    if (newMessage.senderType == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: newMessage.senderType"];
    }
    
    if (newMessage.sender == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: newMessage.sender"];
    }
    
    if (newMessage.recipientType == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: newMessage.recipientType"];
    }
    
    if (newMessage.recipients == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: newMessage.recipients"];
    }
    
    if (newMessage.channelTypeIds == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: newMessage.channelTypeIds"];
    }
    
    NSString* path = [NSString stringWithFormat:@"services/%@/messages", serviceId];
    
    [self postWithModel:newMessage
                   path:path
          responseClass:[ZNGMessage class]
                success:success
                failure:failure];
}

+ (void)markMessageReadWithId:(NSString*)messageId
                       readAt:(NSDate *)readAt
                    serviceId:(NSString*)serviceId
                      success:(void (^)(ZNGMessage* message, ZNGStatus* status))success
                      failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/messages/%@/read", serviceId, messageId];
    
    ZNGMessageRead *messageRead = [[ZNGMessageRead alloc] init];
    messageRead.readAt = readAt;
    
    [self postWithModel:messageRead
                   path:path
          responseClass:[ZNGMessage class]
                success:success
                failure:failure];
}

+ (void)markMessagesReadWithMessageIds:(NSArray *)messageIds
                                readAt:(NSDate *)readAt
                             serviceId:(NSString *)serviceId
                               success:(void (^)(ZNGStatus *))success
                               failure:(void (^)(ZNGError *))failure
{
    
    NSAssert(messageIds != nil && messageIds.count > 0, @"ERROR: There are no messageIds!");
    
    if (messageIds.count == 1) {
        
        [self markMessageReadWithId:[messageIds objectAtIndex:0]
                             readAt:(NSDate *)readAt
                          serviceId:serviceId
                            success:^(ZNGMessage *message, ZNGStatus *status){
            success(status);
        } failure:failure];
    
    } else if (messageIds.count > 1) {
        
        NSString* path = [NSString stringWithFormat:@"services/%@/messages/read", serviceId];
        
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
        parameters[@"message_ids"] = messageIds;
        
        if (readAt) {
            parameters[@"read_at"] = [NSNumber numberWithInteger:(NSInteger)readAt.timeIntervalSince1970];
        }
    
        [self postWithParameters:parameters
                            path:path
                   responseClass:nil
                         success:^(id responseObject, ZNGStatus *status) {
                             success(status);
                         } failure:failure];
        
    }
    
}

// This call should not be made under the Account user authorization class.
+ (void)markAllMessagesReadWithReadAt:(NSDate *)readAt
                            serviceId:(NSString *)serviceId
                              success:(void (^)(ZNGStatus *))success
                              failure:(void (^)(ZNGError *))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/messages/read", serviceId];
    
    NSDictionary *parameters = nil;
    if (readAt) {
        parameters = @{ @"read_at" : [NSNumber numberWithInteger:(NSInteger)readAt.timeIntervalSince1970] };
    }
    
    [self postWithParameters:parameters
                        path:path
               responseClass:nil
                     success:^(id responseObject, ZNGStatus *status) {
                         success(status);
                     } failure:failure];
    
}

+ (void)deleteMessages:(NSArray *)messageIds
         withServiceId:(NSString*)serviceId
               success:(void (^)(ZNGStatus* status))success
               failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/messages/deleted_by_contact", serviceId];
    
    NSDictionary *parameters = @{ @"message_ids" : messageIds };
    
    [self postWithParameters:parameters
                        path:path
               responseClass:nil
                     success:^(id responseObject, ZNGStatus *status) {
                         success(status);
                     }
                     failure:failure];
}

+ (void)deleteAllMessagesForContactId:(NSString *)contactId
                        withServiceId:(NSString*)serviceId
                              success:(void (^)(ZNGStatus* status))success
                              failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/messages/deleted_by_contact", serviceId];
    
    NSDictionary *parameters = @{ @"contact_id" : contactId };
    
    [self postWithParameters:parameters
                        path:path
               responseClass:nil
                     success:^(id responseObject, ZNGStatus *status) {
                         success(status);
                     }
                     failure:failure];
}

@end
