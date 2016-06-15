//
//  ZNGContactChannelClient.h
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import "ZNGBaseClientService.h"
#import "ZNGChannel.h"
#import "ZNGNewChannel.h"

@interface ZNGContactChannelClient : ZNGBaseClientService

#pragma mark - GET methods

- (void)contactChannelWithId:(NSString*)contactChannelId
               withContactId:(NSString*)contactId
                     success:(void (^)(ZNGChannel* contactChannel, ZNGStatus* status))success
                     failure:(void (^)(ZNGError* error))failure;

#pragma mark - POST methods

- (void)saveContactChannel:(ZNGNewChannel*)contactChannel
             withContactId:(NSString*)contactId
                   success:(void (^)(ZNGChannel* contactChannel, ZNGStatus* status))success
                   failure:(void (^)(ZNGError* error))failure;

#pragma mark - DELETE methods

- (void)deleteContactChannelWithId:(NSString*)contactChannelId
                     withContactId:(NSString*)contactId
                           success:(void (^)(ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure;

@end
