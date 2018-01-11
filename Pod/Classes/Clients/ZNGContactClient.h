//
//  ZNGContactClient.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGBaseClientService.h"
#import "ZNGContact.h"
#import "ZNGNewContactFieldValue.h"

@class ZNGNewChannel;

@interface ZNGContactClient : ZNGBaseClientService

#pragma mark - GET methods

- (void)contactListWithParameters:(NSDictionary*)parameters
                          success:(void (^)(NSArray* contacts, ZNGStatus* status))success
                          failure:(void (^)(ZNGError* error))failure;

- (void)contactWithId:(NSString*)contactId
              success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
              failure:(void (^)(ZNGError* error))failure;

- (void)contactChannelWithId:(NSString*)contactChannelId
               withContactId:(NSString*)contactId
                     success:(void (^)(ZNGChannel* contactChannel, ZNGStatus* status))success
                     failure:(void (^)(ZNGError* error))failure;

- (void)findOrCreateContactWithChannelTypeID:(NSString *)channelTypeId
                             andChannelValue:(NSString *)channelValue
                                     success:(void (^) (ZNGContact *contact, ZNGStatus* status))success
                                     failure:(void (^) (ZNGError *error))failure;

#pragma mark - POST methods

- (void)saveContact:(ZNGContact*)contact
            success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure;

- (void)saveContactChannel:(ZNGNewChannel*)contactChannel
             withContactId:(NSString*)contactId
                   success:(void (^)(ZNGChannel* contactChannel, ZNGStatus* status))success
                   failure:(void (^)(ZNGError* error))failure;

- (void)updateContactFieldValue:(ZNGNewContactFieldValue*)contactFieldValue
             withContactFieldId:(NSString*)contactFieldId
                  withContactId:(NSString*)contactId
                        success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure;

- (void)triggerAutomationWithId:(NSString*)automationId
                  withContactId:(NSString*)contactId
                        success:(void (^)(ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure;

- (void) stopAutomationForContactId:(NSString *)contactId
                            success:(void (^)(ZNGStatus* status))success
                            failure:(void (^)(ZNGError* error))failure;

- (void)addLabelWithId:(NSString*)labelId
         withContactId:(NSString*)contactId
               success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
               failure:(void (^)(ZNGError* error))failure;

- (void)unassignContactWithId:(NSString *)contactId
                      success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
                      failure:(void (^)(ZNGError* error))failure;

- (void)assignContactWithId:(NSString *)contactId
                   toUserId:(NSString *)userId
                    success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
                    failure:(void (^)(ZNGError* error))failure;

- (void)assignContactWithId:(NSString *)contactId
                   toTeamId:(NSString *)teamId
                    success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
                    failure:(void (^)(ZNGError* error))failure;

#pragma mark - PUT methods

- (void)updateContactWithId:(NSString*)contactId
             withParameters:(NSDictionary*)parameters
                    success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
                    failure:(void (^)(ZNGError* error))failure;

/**
 *  Updates a channel's display name or default status.  This has no effect if the channel's value has changed.
 */
- (void) updateChannel:(ZNGChannel *)channel
           fromContact:(ZNGContact *)contact
               success:(void (^)(ZNGChannel* channel, ZNGStatus* status))success
               failure:(void (^)(ZNGError* error))failure;

#pragma mark - DELETE methods

- (void)deleteContactWithId:(NSString*)contactId
                    success:(void (^)(ZNGStatus* status))success
                    failure:(void (^)(ZNGError* error))failure;

- (void)removeLabelWithId:(NSString*)labelId
            withContactId:(NSString*)contactId
                  success:(void (^)(ZNGStatus* status))success
                  failure:(void (^)(ZNGError* error))failure;

- (void)deleteContactChannelWithId:(NSString*)contactChannelId
                     withContactId:(NSString*)contactId
                           success:(void (^)(ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure;

#pragma mark - Contact creating/updating
- (void) createContact:(ZNGContact *)contact success:(void (^)(ZNGContact * contact))success failure:(void (^)(ZNGError * error))failure;
- (void) updateContactFrom:(ZNGContact *)oldContact to:(ZNGContact *)newContact success:(void (^)(ZNGContact * contact))success failure:(void (^)(ZNGError * error))failure;

@end
