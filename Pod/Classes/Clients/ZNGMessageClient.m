//
//  ZNGMessageClient.m
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import "ZNGMessageClient.h"
#import "ZNGMessageRead.h"
#import "ZNGNewMessageResponse.h"
#import "ZNGMessageForwardingRequest.h"
#import "ZNGError.h"

@import SBObjectiveCWrapper;

@implementation ZNGMessageClient

#pragma mark - GET methods

- (void)messageListWithParameters:(NSDictionary*)parameters
                          success:(void (^)(NSArray* messages, ZNGStatus* status))success
                          failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/messages", self.serviceId];
    
    [self getListWithParameters:parameters
                           path:path
                  responseClass:[ZNGMessage class]
                        success:success
                        failure:failure];
}

- (void)messageWithId:(NSString*)messageId
              success:(void (^)(ZNGMessage* message, ZNGStatus* status))success
              failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/messages/%@", self.serviceId, messageId];
    
    [self getWithResourcePath:path
                responseClass:[ZNGMessage class]
                      success:success
                      failure:failure];
}

#pragma mark - POST methods

- (void)sendMessage:(ZNGNewMessage*)newMessage
            success:(void (^)(ZNGNewMessageResponse * message, ZNGStatus* status))success
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
    
    NSString* path = [NSString stringWithFormat:@"services/%@/messages", self.serviceId];
    
    [self postWithModel:newMessage
                   path:path
          responseClass:[ZNGNewMessageResponse class]
                success:success
                failure:failure];
}

- (void) forwardMessage:(ZNGMessageForwardingRequest *)forwardingRequest
                success:(void (^)(ZNGStatus* status))success
                failure:(void (^)(ZNGError* error))failure
{
    if ([forwardingRequest.message.messageId length] == 0) {
        SBLogError(@"Unable to forward message with no message ID.");
        
        if (failure != nil) {
            ZNGError * error = [[ZNGError alloc] initWithDomain:kZingleErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : @"Unable to forward a message with no message ID" }];
            failure(error);
            return;
        }
    }
    
    NSString * path = [NSString stringWithFormat:@"services/%@/messages/%@/forward", self.serviceId, forwardingRequest.message.messageId];
    
    [self postWithModel:forwardingRequest path:path responseClass:nil success:^(id  _Nonnull responseObject, ZNGStatus * _Nonnull status) {
        if (success != nil) {
            success(status);
        }
    } failure:failure];
}

- (void)markMessageReadWithId:(NSString*)messageId
                       readAt:(NSDate *)readAt
                      success:(void (^)(ZNGMessage* message, ZNGStatus* status))success
                      failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/messages/%@/read", self.serviceId, messageId];
    
    ZNGMessageRead *messageRead = [[ZNGMessageRead alloc] init];
    messageRead.readAt = readAt;
    
    [self postWithModel:messageRead
                   path:path
          responseClass:[ZNGMessage class]
                success:success
                failure:failure];
}

- (void)markMessagesReadWithMessageIds:(NSArray *)messageIds
                                readAt:(NSDate *)readAt
                               success:(void (^)(ZNGStatus* status))success
                               failure:(void (^)(ZNGError* error))failure
{
    
    NSAssert(messageIds != nil && messageIds.count > 0, @"ERROR: There are no messageIds!");
    
    if (messageIds.count == 1) {
        
        [self markMessageReadWithId:[messageIds objectAtIndex:0]
                             readAt:(NSDate *)readAt
                            success:^(ZNGMessage *message, ZNGStatus *status){
            success(status);
        } failure:failure];
    
    } else if (messageIds.count > 1) {
        
        NSString* path = [NSString stringWithFormat:@"services/%@/messages/read", self.serviceId];
        
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
- (void)markAllMessagesReadWithReadAt:(NSDate *)readAt
                              success:(void (^)(ZNGStatus* status))success
                              failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/messages/read", self.serviceId];
    
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

- (void)deleteMessagesWithIds:(NSArray<NSString *> *)messageIds
                      success:(void (^)(ZNGStatus* status))success
                      failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/messages/deleted_by_contact", self.serviceId];
    
    NSDictionary *parameters = @{ @"message_ids" : messageIds };
    
    [self postWithParameters:parameters
                        path:path
               responseClass:nil
                     success:^(id responseObject, ZNGStatus *status) {
                         success(status);
                     }
                     failure:failure];
}

- (void)deleteAllMessagesForContactId:(NSString *)contactId
                              success:(void (^)(ZNGStatus* status))success
                              failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/messages/deleted_by_contact", self.serviceId];
    
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
