//
//  ZNGContactChannelClient.m
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import "ZNGContactChannelClient.h"
#import "ZNGConstants.h"
#import "ZNGNewContactChannel.h"

@implementation ZNGContactChannelClient

+ (Class)responseObject
{
    return [ZNGContactChannel class];
}

+ (NSString *)resourcePathWithServiceId:(NSString *)serviceId
{
    if (serviceId == nil) [NSException raise:NSInvalidArgumentException format:@"Required argument: serviceId"];
    return [NSString stringWithFormat:kContactsResourcePath, serviceId];
}

#pragma mark - GET methods

+ (void)contactChannelWithId:(NSString *)contactChannelId
               withContactId:(NSString *)contactId
               withServiceId:(NSString *)serviceId
                     success:(void (^)(ZNGContactChannel *contactChannel))success
                     failure:(void (^)(ZNGError *error))failure
{
    NSString *channelsPath = [NSString stringWithFormat: @"/%@/channels/%@", contactId, contactChannelId];
    NSString *path = [[self resourcePathWithServiceId:serviceId] stringByAppendingString:channelsPath];
    
    [self getWithResourcePath:path
                responseClass:[self responseObject]
                      success:success
                      failure:failure];
}

#pragma mark - POST methods

+ (void)saveContactChannel:(ZNGContactChannel *)contactChannel
             withContactId:(NSString *)contactId
             withServiceId:(NSString *)serviceId
                   success:(void (^)(ZNGContactChannel *contactChannel))success
                   failure:(void (^)(ZNGError *error))failure
{
    if (contactChannel.channelType.channelTypeId == nil) [NSException raise:NSInvalidArgumentException format:@"Required argument: contactChannel.channelType.channelTypeId"];
    if (contactChannel.value == nil) [NSException raise:NSInvalidArgumentException format:@"Required argument: contactChannel.value"];
    if (contactChannel.country == nil) [NSException raise:NSInvalidArgumentException format:@"Required argument: contactChannel.country"];
    
    NSString *channelsPath = [NSString stringWithFormat: @"/%@/channels", contactId];
    NSString *path = [[self resourcePathWithServiceId:serviceId] stringByAppendingString:channelsPath];
    
    ZNGNewContactChannel *newContactChannel = [[ZNGNewContactChannel alloc] initWithContactChannel:contactChannel];
    [self postWithModel:newContactChannel
                   path:path
          responseClass:[self responseObject]
                success:success
                failure:failure];

}

#pragma mark - PUT methods

+ (void)updateContactChannelWithId:(NSString *)contactChannelId
                    withParameters:(NSDictionary *)parameters
                     withContactId:(NSString *)contactId
                     withServiceId:(NSString *)serviceId
                           success:(void (^)(ZNGContactChannel *contactChannel))success
                           failure:(void (^)(ZNGError *error))failure
{
    NSString *channelsPath = [NSString stringWithFormat: @"/%@/channels/%@", contactId, contactChannelId];
    NSString *path = [[self resourcePathWithServiceId:serviceId] stringByAppendingString:channelsPath];
    
    [self putWithPath:path
           parameters:parameters
        responseClass:[self responseObject]
              success:success
              failure:failure];
}

#pragma mark - DELETE methods

+ (void)deleteContactChannelWithId:(NSString *)contactChannelId
                     withContactId:(NSString *)contactId
                     withServiceId:(NSString *)serviceId
                           success:(void (^)())success
                           failure:(void (^)(ZNGError *error))failure
{
    NSString *channelsPath = [NSString stringWithFormat: @"/%@/channels/%@", contactId, contactChannelId];
    NSString *path = [[self resourcePathWithServiceId:serviceId] stringByAppendingString:channelsPath];
    
    [self deleteWithPath:path
                 success:success
                 failure:failure];
}


@end
