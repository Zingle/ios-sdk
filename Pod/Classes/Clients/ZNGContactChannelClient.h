//
//  ZNGContactChannelClient.h
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGContactChannel.h"
#import "ZNGNewContactChannel.h"

@interface ZNGContactChannelClient : ZNGBaseClient

#pragma mark - GET methods

+ (void)contactChannelWithId:(NSString*)contactChannelId
               withContactId:(NSString*)contactId
               withServiceId:(NSString*)serviceId
                     success:(void (^)(ZNGContactChannel* contactChannel, ZNGStatus* status))success
                     failure:(void (^)(ZNGError* error))failure;

#pragma mark - POST methods

+ (void)saveContactChannel:(ZNGNewContactChannel*)contactChannel
             withContactId:(NSString*)contactId
             withServiceId:(NSString*)serviceId
                   success:(void (^)(ZNGContactChannel* contactChannel, ZNGStatus* status))success
                   failure:(void (^)(ZNGError* error))failure;

#pragma mark - PUT methods

+ (void)updateContactChannelWithId:(NSString*)contactChannelId
                    withParameters:(NSDictionary*)parameters
                     withContactId:(NSString*)contactId
                     withServiceId:(NSString*)serviceId
                           success:(void (^)(ZNGContactChannel* contactChannel, ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure;

#pragma mark - DELETE methods

+ (void)deleteContactChannelWithId:(NSString*)contactChannelId
                     withContactId:(NSString*)contactId
                     withServiceId:(NSString*)serviceId
                           success:(void (^)(ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure;

@end
