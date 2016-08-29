//
//  ZNGContactClient.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGContactClient.h"
#import "ZNGNewContact.h"
#import "ZNGLogging.h"
#import "ZNGLabel.h"
#import "ZNGError.h"

static const int zngLogLevel = ZNGLogLevelVerbose;

@implementation ZNGContactClient

#pragma mark - GET methods

- (void)contactListWithParameters:(NSDictionary*)parameters
                          success:(void (^)(NSArray* contacts, ZNGStatus* status))success
                          failure:(void (^)(ZNGError* error))failure;
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts", self.serviceId];
    
    [self getListWithParameters:parameters
                           path:path
                  responseClass:[ZNGContact class]
                        success:success
                        failure:failure];
}

- (void)contactWithId:(NSString*)contactId
              success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
              failure:(void (^)(ZNGError* error))failure;
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@", self.serviceId, contactId];
    
    [self getWithResourcePath:path
                responseClass:[ZNGContact class]
                      success:success
                      failure:failure];
}

- (void)findOrCreateContactWithChannelTypeID:(NSString *)channelTypeId
                             andChannelValue:(NSString *)channelValue
                                     success:(void (^) (ZNGContact *contact, ZNGStatus* status))success
                                     failure:(void (^) (ZNGError *error))failure
{
    NSDictionary *channels = @{ @"value" : channelValue,
                                @"channel_type_id" : channelTypeId };
    NSDictionary *params = @{ @"channels" : @[ channels ]};
    
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts?return_existing=1", self.serviceId];
    
    [self postWithParameters:params
                   path:path
          responseClass:[ZNGContact class]
                success:success
                failure:failure];
}

#pragma mark - POST methods

- (void)saveContact:(ZNGContact*)contact
            success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure
{
    ZNGNewContact* newContact = [[ZNGNewContact alloc] initWithContact:contact];
    
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts", self.serviceId];
    
    [self postWithModel:newContact
                   path:path
          responseClass:[ZNGContact class]
                success:success
                failure:failure];
}

- (void)updateContactFieldValue:(ZNGNewContactFieldValue*)contactFieldValue
             withContactFieldId:(NSString*)contactFieldId
                  withContactId:(NSString*)contactId
                        success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@/custom-field-values/%@", self.serviceId, contactId, contactFieldId];
    
    [self postWithModel:contactFieldValue
                   path:path
          responseClass:[ZNGContact class]
                success:success
                failure:failure];
}

- (void)triggerAutomationWithId:(NSString*)automationId
                  withContactId:(NSString*)contactId
                        success:(void (^)(ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@/automations/%@", self.serviceId, contactId, automationId];
    
    [self postWithModel:nil
                   path:path
          responseClass:nil
                success:^(id responseObject, ZNGStatus *status) {
                    success(status);
                } failure:failure];
}

- (void)addLabelWithId:(NSString*)labelId
         withContactId:(NSString*)contactId
               success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
               failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@/labels/%@", self.serviceId, contactId, labelId];
    
    [self postWithModel:nil
                   path:path
          responseClass:[ZNGContact class]
                success:success
                failure:failure];
}

#pragma mark - PUT methods

- (void)updateContactWithId:(NSString*)contactId
             withParameters:(NSDictionary*)parameters
                    success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
                    failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@", self.serviceId, contactId];
    
    [self putWithPath:path
           parameters:parameters
        responseClass:[ZNGContact class]
              success:success
              failure:failure];
}

#pragma mark - DELETE methods

- (void)deleteContactWithId:(NSString*)contactId
                    success:(void (^)(ZNGStatus* status))success
                    failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@", self.serviceId, contactId];
    
    [self deleteWithPath:path
                 success:success
                 failure:failure];
}

- (void)removeLabelWithId:(NSString*)labelId
            withContactId:(NSString*)contactId
                  success:(void (^)(ZNGStatus* status))success
                  failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@/labels/%@", self.serviceId, contactId, labelId];
    
    [self deleteWithPath:path
                 success:success
                 failure:failure];
}

#pragma mark - Contact editing convenience methods
- (void) createContact:(ZNGContact *)contact success:(void (^ _Nullable)(ZNGContact * _Nonnull contact))success failure:(void (^ _Nullable)(ZNGError * _Nonnull error))failure
{
    [self updateContactFrom:nil to:contact success:success failure:failure];
}

- (void) updateContactFrom:(ZNGContact *)oldContact to:(ZNGContact *)newContact success:(void (^)(ZNGContact * contact))success failure:(void (^)(ZNGError * error))failure
{
    // Create a deep copy of the new contact
    NSDictionary * contactAsDictionary = [MTLJSONAdapter JSONDictionaryFromModel:newContact error:nil];
    ZNGContact * changedContact = [MTLJSONAdapter modelOfClass:[ZNGContact class] fromJSONDictionary:contactAsDictionary error:nil];
    
    // Remove any empty fields and channels
    changedContact.channels = [changedContact channelsWithValues];
    changedContact.customFieldValues = [changedContact customFieldsWithValues];
    
    // Find any label changes
    NSMutableOrderedSet<ZNGLabel *> * oldContactLabels = ([oldContact.labels count] > 0) ? [NSMutableOrderedSet orderedSetWithArray:oldContact.labels] : [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet<ZNGLabel *> * newContactLabels = ([newContact.labels count] > 0) ? [NSMutableOrderedSet orderedSetWithArray:newContact.labels] : [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet<ZNGLabel *> * addedLabels = [newContactLabels mutableCopy];
    [addedLabels minusOrderedSet:oldContactLabels];
    NSMutableOrderedSet<ZNGLabel *> * removedLabels = oldContactLabels;
    [removedLabels minusOrderedSet:newContactLabels];
    
    void (^contactUpdateSuccessBlock)(ZNGContact *, ZNGStatus *) = ^void(ZNGContact * contact, ZNGStatus * status) {
        ZNGLogDebug(@"Updating contact (but not yet labels if present) succeeded.");
        
        // If we have no label changes, we are done
        if (([addedLabels count] == 0) && ([removedLabels count] == 0)) {
            // We're done
            if (success != nil) {
                success(contact);
            }
            
            return;
        }
        
        // We have label changes to make
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL labelSuccess = YES;
            
            for (ZNGLabel * label in addedLabels) {
                labelSuccess = [self _synchronouslyAddLabel:label toContact:contact timeout:15.0];
                if (!labelSuccess) {
                    break;
                }
            }
            
            for (ZNGLabel * label in removedLabels) {
                if (!labelSuccess) {
                    break;
                }
                
                [self _synchronouslyRemoveLabel:label fromContact:contact timeout:15.0];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (labelSuccess) {
                    if (success != nil) {
                        contact.labels = [newContactLabels array];
                        success(contact);
                    }
                } else {
                    if (failure != nil) {
                        ZNGError * error = [[ZNGError alloc] init];
                        failure(nil);
                    }
                }
            });
        });
    };
    
    // Are we updating or creating?
    if ([newContact.contactId length] == 0) {
        // Creating
        [self saveContact:changedContact success:contactUpdateSuccessBlock failure:failure];
    } else {
        // Updating
        NSMutableDictionary<NSString *, id> * parameters = [[NSMutableDictionary alloc] init];
        
        if ([changedContact.channels count] > 0) {
            parameters[@"channels"] = [MTLJSONAdapter JSONArrayFromModels:changedContact.channels error:nil];
        }
        
        if ([changedContact.customFieldValues count] > 0) {
            parameters[@"custom_field_values"] = [MTLJSONAdapter JSONArrayFromModels:changedContact.customFieldValues error:nil];
        }
        
        // Note: Using this logic instead of just @(boolValue) is necessary because the Zingle server does not accept 0 and 1 as boolean.  This is Nathan's fault.
        parameters[@"is_starred"] = changedContact.isStarred ? @YES : @NO;
        parameters[@"is_confirmed"] = changedContact.isConfirmed ? @YES : @NO;
        
        
        [self updateContactWithId:newContact.contactId withParameters:parameters success:contactUpdateSuccessBlock failure:failure];
    }
}

- (BOOL) _synchronouslyAddLabel:(ZNGLabel *)label toContact:(ZNGContact *)contact timeout:(NSTimeInterval)timeout
{
    dispatch_time_t semaphoreTimeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC));
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BOOL success;
    
    [self addLabelWithId:label.labelId withContactId:contact.contactId success:^(ZNGContact *contact, ZNGStatus *status) {
        ZNGLogVerbose(@"Added label %@ to %@", label.displayName, [contact fullName]);
        dispatch_semaphore_signal(semaphore);
        success = YES;
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Unable to add label %@ to %@: %@", label.displayName, [contact fullName], error);
        dispatch_semaphore_signal(semaphore);
        success = NO;
    }];
    
    long result = dispatch_semaphore_wait(semaphore, semaphoreTimeout);
    return (result == 0) ? success : NO;
}

- (BOOL) _synchronouslyRemoveLabel:(ZNGLabel *)label fromContact:(ZNGContact *)contact timeout:(NSTimeInterval)timeout
{
    dispatch_time_t semaphoreTimeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC));
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BOOL success;
    
    [self removeLabelWithId:label.labelId withContactId:contact.contactId success:^(ZNGStatus *status) {
        ZNGLogVerbose(@"Removed label %@ from %@", label.displayName, [contact fullName]);
        dispatch_semaphore_signal(semaphore);
        success = YES;
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Unable to remove label %@ from %@: %@", label.displayName, [contact fullName], error);
        dispatch_semaphore_signal(semaphore);
        success = NO;
    }];
    
    long result = dispatch_semaphore_wait(semaphore, semaphoreTimeout);
    return (result == 0) ? success : NO;
}

@end
