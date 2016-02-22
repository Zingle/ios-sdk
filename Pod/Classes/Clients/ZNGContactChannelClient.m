//
//  ZNGContactChannelClient.m
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import "ZNGContactChannelClient.h"


@implementation ZNGContactChannelClient

#pragma mark - GET methods

+ (void)contactChannelWithId:(NSString*)contactChannelId
               withContactId:(NSString*)contactId
               withServiceId:(NSString*)serviceId
                     success:(void (^)(ZNGContactChannel* contactChannel, ZNGStatus* status))success
                     failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@/channels/%@", serviceId, contactId, contactChannelId];
    
    [self getWithResourcePath:path
                responseClass:[ZNGContactChannel class]
                      success:success
                      failure:failure];
}

#pragma mark - POST methods

+ (void)saveContactChannel:(ZNGNewContactChannel*)contactChannel
             withContactId:(NSString*)contactId
             withServiceId:(NSString*)serviceId
                   success:(void (^)(ZNGContactChannel* contactChannel, ZNGStatus* status))success
                   failure:(void (^)(ZNGError* error))failure
{
    if (contactChannel.channelTypeId == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: contactChannel.channelType.channelTypeId"];
    }
    
    if (contactChannel.value == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: contactChannel.value"];
    }
    
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@/channels", serviceId, contactId];
    
    [self postWithModel:contactChannel
                   path:path
          responseClass:[ZNGContactChannel class]
                success:success
                failure:failure];
}

#pragma mark - PUT methods

+ (void)updateContactChannelWithId:(NSString*)contactChannelId
                    withParameters:(NSDictionary*)parameters
                     withContactId:(NSString*)contactId
                     withServiceId:(NSString*)serviceId
                           success:(void (^)(ZNGContactChannel* contactChannel, ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@/channels/%@", serviceId, contactId, contactChannelId];
    
    [self putWithPath:path
           parameters:parameters
        responseClass:[ZNGContactChannel class]
              success:success
              failure:failure];
}

#pragma mark - DELETE methods

+ (void)deleteContactChannelWithId:(NSString*)contactChannelId
                     withContactId:(NSString*)contactId
                     withServiceId:(NSString*)serviceId
                           success:(void (^)(ZNGStatus* state))success
                           failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@/channels/%@", serviceId, contactId, contactChannelId];
    
    [self deleteWithPath:path
                 success:success
                 failure:failure];
}

@end
