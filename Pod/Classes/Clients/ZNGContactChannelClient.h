//
//  ZNGContactChannelClient.h
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGContactChannel.h"

@interface ZNGContactChannelClient : ZNGBaseClient

#pragma mark - GET methods

+ (void)contactChannelWithId:(NSString *)contactChannelId
               withContactId:(NSString *)contactId
               withServiceId:(NSString *)serviceId
                     success:(void (^)(ZNGContactChannel *contactChannel))success
                     failure:(void (^)(ZNGError *error))failure;

#pragma mark - POST methods

+ (void)saveContactChannel:(ZNGContactChannel *)contactChannel
             withContactId:(NSString *)contactId
             withServiceId:(NSString *)serviceId
                   success:(void (^)(ZNGContactChannel *contactChannel))success
                   failure:(void (^)(ZNGError *error))failure;

#pragma mark - PUT methods

+ (void)updateContactChannelWithId:(NSString *)contactChannelId
                    withParameters:(NSDictionary *)parameters
                     withContactId:(NSString *)contactId
                     withServiceId:(NSString *)serviceId
                           success:(void (^)(ZNGContactChannel *contactChannel))success
                           failure:(void (^)(ZNGError *error))failure;

#pragma mark - DELETE methods

+ (void)deleteContactChannelWithId:(NSString *)contactChannelId
                     withContactId:(NSString *)contactId
                     withServiceId:(NSString *)serviceId
                           success:(void (^)())success
                           failure:(void (^)(ZNGError *error))failure;

@end
