//
//  ZNGContactClient.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGContactClient.h"
#import "ZNGConstants.h"
#import "ZNGNewContact.h"

@implementation ZNGContactClient

#pragma mark - ZNGClientProtocol

+ (Class)responseObject
{
    return [ZNGContact class];
}

+ (NSString *)resourcePathWithServiceId:(NSString *)serviceId
{
    if (serviceId == nil) [NSException raise:NSInvalidArgumentException format:@"Required argument: serviceId"];
    return [NSString stringWithFormat:kContactsResourcePath, serviceId];
}


#pragma mark - GET methods

+ (void)contactListWithServiceId:(NSString *)serviceId
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(NSArray *contacts))success
                         failure:(void (^)(ZNGError *error))failure
{
    [self getListWithParameters:parameters
                           path:[self resourcePathWithServiceId:serviceId]
                 responseClass:[self responseObject]
                        success:success
                        failure:failure];
}

+ (void)contactWithId:(NSString *)contactId
        withServiceId:(NSString *)serviceId
              success:(void (^)(ZNGContact *contact))success
              failure:(void (^)(ZNGError *error))failure
{
    NSString *idPath = contactId ? [NSString stringWithFormat:@"/%@", contactId] : @"";
    NSString *path = [NSString stringWithFormat:@"%@%@",[self resourcePathWithServiceId:serviceId], idPath];
    
    [self getWithResourcePath:path
               responseClass:[self responseObject]
                      success:success
                      failure:failure];
}

#pragma mark - POST methods

+ (void)saveContact:(ZNGContact *)contact
      withServiceId:(NSString *)serviceId
            success:(void (^)(ZNGContact *contact))success
            failure:(void (^)(ZNGError *error))failure
{
    ZNGNewContact *newContact = [[ZNGNewContact alloc] initWithContact:contact];
    
    [self postWithModel:newContact
                   path:[self resourcePathWithServiceId:serviceId]
         responseClass:[self responseObject]
                success:success
                failure:failure];
}

+ (void)updateContactCustomFieldValue:(ZNGCustomFieldValue *)contactCustomFieldValue
                    withCustomFieldId:(NSString *)customFieldId
                        withContactId:(NSString *)contactId
                        withServiceId:(NSString *)serviceId
                              success:(void (^)(ZNGContact *contact))success
                              failure:(void (^)(ZNGError *error))failure
{
    NSString *customFieldPath = [NSString stringWithFormat: @"/%@/custom-field-values/%@", contactId, customFieldId];
    NSString *path = [[self resourcePathWithServiceId:serviceId] stringByAppendingString:customFieldPath];
    
    [self postWithModel:contactCustomFieldValue
                   path:path
         responseClass:[self responseObject]
                success:success
                failure:failure];
}

+ (void)triggerAutomationWithId:(NSString *)automationId
                  withContactId:(NSString *)contactId
                  withServiceId:(NSString *)serviceId
                        success:(void (^)(ZNGContact *contact))success
                        failure:(void (^)(ZNGError *error))failure
{
    NSString *automationPath = [NSString stringWithFormat: @"/%@/automations/%@", contactId, automationId];
    NSString *path = [[self resourcePathWithServiceId:serviceId] stringByAppendingString:automationPath];
    
    [self postWithModel:nil
                   path:path
          responseClass:nil
                success:success
                failure:failure];
}

+ (void)addLabelWithId:(NSString *)labelId
         withContactId:(NSString *)contactId
         withServiceId:(NSString *)serviceId
               success:(void (^)(ZNGContact *contact))success
               failure:(void (^)(ZNGError *error))failure
{
    NSString *labelPath = [NSString stringWithFormat: @"/%@/labels/%@", contactId, labelId];
    NSString *path = [[self resourcePathWithServiceId:serviceId] stringByAppendingString:labelPath];
    
    [self postWithModel:nil
                   path:path
          responseClass:nil
                success:success
                failure:failure];
}

#pragma mark - PUT methods

+ (void)updateContactWithId:(NSString *)contactId
              withServiceId:(NSString *)serviceId
             withParameters:(NSDictionary *)parameters
                    success:(void (^)(ZNGContact *contact))success
                    failure:(void (^)(ZNGError *error))failure
{
    NSString *idPath = contactId ? [NSString stringWithFormat:@"/%@", contactId] : @"";
    NSString *path = [NSString stringWithFormat:@"%@%@",[self resourcePathWithServiceId:serviceId], idPath];
    
    [self putWithPath:path
           parameters:parameters
       responseClass:[self responseObject]
              success:success
              failure:failure];
}

#pragma mark - DELETE methods

+ (void)deleteContactWithId:(NSString *)contactId
              withServiceId:(NSString *)serviceId
                    success:(void (^)())success
                    failure:(void (^)(ZNGError *error))failure
{
    NSString *idPath = contactId ? [NSString stringWithFormat:@"/%@", contactId] : @"";
    NSString *path = [NSString stringWithFormat:@"%@%@",[self resourcePathWithServiceId:serviceId], idPath];
    
    [self deleteWithPath:path
                 success:success
                 failure:failure];
}

+ (void)removeLabelWithId:(NSString *)labelId
            withContactId:(NSString *)contactId
            withServiceId:(NSString *)serviceId
                  success:(void (^)(ZNGContact *contact))success
                  failure:(void (^)(ZNGError *error))failure
{
    NSString *labelPath = [NSString stringWithFormat: @"/%@/labels/%@", contactId, labelId];
    NSString *path = [[self resourcePathWithServiceId:serviceId] stringByAppendingString:labelPath];
    
    [self deleteWithPath:path
                 success:success
                 failure:failure];
}

@end
