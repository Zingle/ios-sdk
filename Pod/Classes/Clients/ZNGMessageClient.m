//
//  ZNGMessageClient.m
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import "ZNGMessageClient.h"
#import "ZNGConstants.h"

@implementation ZNGMessageClient

#pragma mark - GET methods

+ (void)messageListWithParameters:(NSDictionary*)parameters
                    withServiceId:(NSString*)serviceId
                          success:(void (^)(NSArray* messages))success
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
              success:(void (^)(ZNGMessage* message))success
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
            success:(void (^)(ZNGMessage* message))success
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
                withChannelId:(NSString*)channelId
                withServiceId:(NSString*)serviceId
                      success:(void (^)(ZNGMessage* message))success
                      failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/channels/%@/messages/%@", serviceId, channelId, messageId];
    
    [self postWithModel:@{@"read_at" : [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]}
                   path:path
          responseClass:[ZNGMessage class]
                success:success
                failure:failure];
}

@end
