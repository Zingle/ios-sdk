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
#import "ZNGNewChannel.h"

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

- (void)contactChannelWithId:(NSString*)contactChannelId
               withContactId:(NSString*)contactId
                     success:(void (^)(ZNGChannel* contactChannel, ZNGStatus* status))success
                     failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@/channels/%@", self.serviceId, contactId, contactChannelId];
    
    [self getWithResourcePath:path
                responseClass:[ZNGChannel class]
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

- (void)saveContactChannel:(ZNGNewChannel*)contactChannel
             withContactId:(NSString*)contactId
                   success:(void (^)(ZNGChannel* contactChannel, ZNGStatus* status))success
                   failure:(void (^)(ZNGError* error))failure
{
    if (contactChannel.channelTypeId == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: contactChannel.channelType.channelTypeId"];
    }
    
    if (contactChannel.value == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: contactChannel.value"];
    }
    
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@/channels", self.serviceId, contactId];
    
    [self postWithModel:contactChannel
                   path:path
          responseClass:[ZNGChannel class]
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

- (void) updateChannel:(ZNGChannel *)channel fromContact:(ZNGContact *)contact success:(void (^)(ZNGChannel* channel, ZNGStatus* status))success
               failure:(void (^)(ZNGError* error))failure
{
    NSString * path = [NSString stringWithFormat:@"services/%@/contacts/%@/channels/%@", self.serviceId, contact.contactId, channel.channelId];
    
    NSDictionary * parameters = @{ @"display_name" : channel.displayName,
                                   @"is_default" : (channel.isDefault ? @YES : @NO),
                                   @"is_default_for_type" : (channel.isDefaultForType ? @YES : @NO) };
    
    [self putWithPath:path parameters:parameters responseClass:[ZNGChannel class] success:success failure:failure];
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


- (void)deleteContactChannelWithId:(NSString*)contactChannelId
                     withContactId:(NSString*)contactId
                           success:(void (^)(ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@/channels/%@", self.serviceId, contactId, contactChannelId];
    
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
    // Create a copy of the new contact.  ZNGContact promises a deep copy.
    ZNGContact * changedContact = [newContact copy];
    
    // Detect deleted custom fields
    NSArray<ZNGNewContactFieldValue *> * deletedCustomFields = [newContact customFieldsDeletedSince:oldContact];
    
    // Remove any empty fields and channels
    changedContact.channels = [changedContact channelsWithValues];
    changedContact.customFieldValues = [[changedContact customFieldsWithValuesAsNewValueObjects] arrayByAddingObjectsFromArray:deletedCustomFields];
    
    // Find any label changes
    NSMutableOrderedSet<ZNGLabel *> * oldContactLabels = ([oldContact.labels count] > 0) ? [NSMutableOrderedSet orderedSetWithArray:oldContact.labels] : [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet<ZNGLabel *> * newContactLabels = ([newContact.labels count] > 0) ? [NSMutableOrderedSet orderedSetWithArray:newContact.labels] : [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet<ZNGLabel *> * addedLabels = [newContactLabels mutableCopy];
    [addedLabels minusOrderedSet:oldContactLabels];
    NSMutableOrderedSet<ZNGLabel *> * removedLabels = oldContactLabels;
    [removedLabels minusOrderedSet:newContactLabels];
    
    // Find any channel changes
    NSArray<ZNGChannel *> * oldChannelsWithValues = [oldContact channelsWithValues];
    NSMutableOrderedSet<ZNGChannel *> * oldChannels = ([oldChannelsWithValues count] > 0) ? [NSMutableOrderedSet orderedSetWithArray:oldChannelsWithValues] : [[NSMutableOrderedSet alloc] init];
    NSArray<ZNGChannel *> * newChannelsWithValues = [newContact channelsWithValues];
    NSMutableOrderedSet<ZNGChannel *> * newChannels = ([newChannelsWithValues count] > 0) ? [NSMutableOrderedSet orderedSetWithArray:newChannelsWithValues] : [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet<ZNGChannel *> * addedChannels = [newChannels mutableCopy];
    NSMutableOrderedSet<ZNGChannel *> * channelsInBoth = [newChannels mutableCopy];
    [channelsInBoth intersectOrderedSet:oldChannels];
    [addedChannels minusOrderedSet:oldChannels];
    NSMutableOrderedSet<ZNGChannel *> * removedChannels = [oldChannels mutableCopy];
    [removedChannels minusOrderedSet:newChannels];
    
    NSMutableArray<ZNGChannel *> * changedValueChannels = [[NSMutableArray alloc] initWithCapacity:[channelsInBoth count]];
    NSMutableArray<ZNGChannel *> * changedOtherwiseChannels = [[NSMutableArray alloc] initWithCapacity:[channelsInBoth count]];
    
    for (ZNGChannel * channel in channelsInBoth) {
        NSUInteger oldChannelIndex = [oldChannels indexOfObject:channel];
        NSUInteger newChannelIndex = [newChannels indexOfObject:channel];
        ZNGChannel * oldChannel = [oldChannels objectAtIndex:oldChannelIndex];
        ZNGChannel * newChannel = [newChannels objectAtIndex:newChannelIndex];
        
        if ([newChannel changedSince:oldChannel]) {
            if (![[newChannel valueForComparison] isEqualToString:[oldChannel valueForComparison]]) {
                [changedValueChannels addObject:newChannel];
            } else {
                [changedOtherwiseChannels addObject:newChannel];
            }
        }
    }
    
    void (^contactUpdateSuccessBlock)(ZNGContact *, ZNGStatus *) = ^void(ZNGContact * contact, ZNGStatus * status) {
        ZNGLogDebug(@"Updating contact (but not yet labels if present) succeeded.");
        contact.contactClient = self;
        
        // If we have no label nor channel changes, we are done
        NSUInteger labelAndChannelChangeCount = [addedLabels count] + [removedLabels count] + [addedChannels count] + [removedChannels count] + [changedValueChannels count] + [changedOtherwiseChannels count];
        if (labelAndChannelChangeCount == 0) {
            // We're done
            if (success != nil) {
                success(contact);
            }
            
            return;
        }
        
        // We have label or channel changes to make
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL syncSuccess = YES;
            static NSTimeInterval timeout = 10.0;
            ZNGError * error = nil;
            
            for (ZNGLabel * label in addedLabels) {
                syncSuccess = [self _synchronouslyAddLabel:label toContact:contact timeout:timeout error:&error];
                if (!syncSuccess) {
                    break;
                }
            }
            
            for (ZNGLabel * label in removedLabels) {
                if (!syncSuccess) {
                    break;
                }
                
                syncSuccess = [self _synchronouslyRemoveLabel:label fromContact:contact timeout:timeout error:&error];
            }
            
            for (ZNGChannel * channel in addedChannels) {
                if (!syncSuccess) {
                    break;
                }
                
                syncSuccess = [self _synchronouslyAddChannel:channel toContact:contact timeout:timeout error:&error];
            }
            
            for (ZNGChannel * channel in removedChannels) {
                if (!syncSuccess) {
                    break;
                }
                
                syncSuccess = [self _synchronouslyRemoveChannel:channel fromContact:contact timeout:timeout error:&error];
            }
            
            for (ZNGChannel * channel in changedValueChannels) {
                if (!syncSuccess) {
                    break;
                }
                
                syncSuccess = [self _synchronouslyRemoveChannel:channel fromContact:contact timeout:timeout error:&error];
                channel.channelId = nil;
                syncSuccess &= [self _synchronouslyAddChannel:channel toContact:contact timeout:timeout error:&error];
            }
            
            for (ZNGChannel * channel in changedOtherwiseChannels) {
                if (!syncSuccess) {
                    break;
                }
                
                syncSuccess = [self _synchronouslyUpdateChannel:channel fromContact:contact timeout:timeout error:&error];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (syncSuccess) {
                    // If we have a success callback, we'll make one more request to retrieve an up-to-date contact object with all labels and channels.
                    if (success != nil) {
                        [self contactWithId:contact.contactId success:^(ZNGContact * updatedContact, ZNGStatus *status) {
                            updatedContact.contactClient = self;
                            [oldContact updateWithNewData:updatedContact];
                            success(updatedContact);
                        } failure:^(ZNGError *error) {
                            ZNGLogWarn(@"Creating/updating %@ was fully successful, but the request for most up to date data failed after all updates.  Data returned may be \
                                       slightly stale", [contact fullName]);
                            success(contact);
                        }];
                    }
                } else {
                    if (failure != nil) {
                        failure(error);
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
        
        if ([changedContact.customFieldValues count] > 0) {
            parameters[@"custom_field_values"] = [MTLJSONAdapter JSONArrayFromModels:changedContact.customFieldValues];
        }
        
        // Note: Using this logic instead of just @(boolValue) is necessary because the Zingle server does not accept 0 and 1 as boolean.  This is Nathan's fault.
        parameters[@"is_starred"] = changedContact.isStarred ? @YES : @NO;
        parameters[@"is_confirmed"] = changedContact.isConfirmed ? @YES : @NO;
        
        
        [self updateContactWithId:newContact.contactId withParameters:parameters success:contactUpdateSuccessBlock failure:failure];
    }
}

- (BOOL) _synchronouslyAddLabel:(ZNGLabel *)label toContact:(ZNGContact *)contact timeout:(NSTimeInterval)timeout error:(ZNGError * __autoreleasing *)error
{
    dispatch_time_t semaphoreTimeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC));
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BOOL success;
    
    [self addLabelWithId:label.labelId withContactId:contact.contactId success:^(ZNGContact *contact, ZNGStatus *status) {
        ZNGLogVerbose(@"Added label %@ to %@", label.displayName, [contact fullName]);
        dispatch_semaphore_signal(semaphore);
        success = YES;
    } failure:^(ZNGError * anError) {
        ZNGLogError(@"Unable to add label %@ to %@: %@", label.displayName, [contact fullName], anError);
        dispatch_semaphore_signal(semaphore);
        success = NO;
        *error = anError;
    }];
    
    long result = dispatch_semaphore_wait(semaphore, semaphoreTimeout);
    return (result == 0) ? success : NO;
}

- (BOOL) _synchronouslyRemoveLabel:(ZNGLabel *)label fromContact:(ZNGContact *)contact timeout:(NSTimeInterval)timeout error:(ZNGError * __autoreleasing *)error
{
    dispatch_time_t semaphoreTimeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC));
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BOOL success;
    
    [self removeLabelWithId:label.labelId withContactId:contact.contactId success:^(ZNGStatus *status) {
        ZNGLogVerbose(@"Removed label %@ from %@", label.displayName, [contact fullName]);
        dispatch_semaphore_signal(semaphore);
        success = YES;
    } failure:^(ZNGError * anError) {
        ZNGLogError(@"Unable to remove label %@ from %@: %@", label.displayName, [contact fullName], anError);
        dispatch_semaphore_signal(semaphore);
        success = NO;
        *error = anError;
    }];
    
    long result = dispatch_semaphore_wait(semaphore, semaphoreTimeout);
    return (result == 0) ? success : NO;
}

- (BOOL) _synchronouslyAddChannel:(ZNGChannel *)channel toContact:(ZNGContact *)contact timeout:(NSTimeInterval)timeout error:(ZNGError * __autoreleasing *)error
{
    dispatch_time_t semaphoreTimeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC));
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BOOL success;
    
    ZNGNewChannel * newChannel = [[ZNGNewChannel alloc] initWithChannel:channel];
    [self saveContactChannel:newChannel withContactId:contact.contactId success:^(ZNGChannel *contactChannel, ZNGStatus *status) {
        ZNGLogVerbose(@"Added channel %@ to %@", channel.value, [contact fullName]);
        dispatch_semaphore_signal(semaphore);
        success = YES;
    } failure:^(ZNGError * anError) {
        ZNGLogError(@"Unable to add channel %@ to %@: %@", channel.value, [contact fullName], anError);
        dispatch_semaphore_signal(semaphore);
        success = NO;
        *error = anError;
    }];
    
    long result = dispatch_semaphore_wait(semaphore, semaphoreTimeout);
    return (result == 0) ? success : NO;
}

- (BOOL) _synchronouslyUpdateChannel:(ZNGChannel *)channel fromContact:(ZNGContact *)contact timeout:(NSTimeInterval)timeout error:(ZNGError * __autoreleasing *)error
{
    dispatch_time_t semaphoreTimeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC));
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BOOL success;
    
    [self updateChannel:channel fromContact:contact success:^(ZNGChannel *channel, ZNGStatus *status) {
        ZNGLogVerbose(@"Updated %@ channel", channel.formattedValue);
        dispatch_semaphore_signal(semaphore);
        success = YES;
    } failure:^(ZNGError * anError) {
        ZNGLogError(@"Unable to update %@ channel: %@", channel.formattedValue, anError);
        success = NO;
        *error = anError;
    }];
    
    long result = dispatch_semaphore_wait(semaphore, semaphoreTimeout);
    return (result == 0) ? success : NO;
}

- (BOOL) _synchronouslyRemoveChannel:(ZNGChannel *)channel fromContact:(ZNGContact *)contact timeout:(NSTimeInterval)timeout error:(ZNGError * __autoreleasing *)error
{
    dispatch_time_t semaphoreTimeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC));
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BOOL success;
    
    [self deleteContactChannelWithId:channel.channelId withContactId:contact.contactId success:^(ZNGStatus *status) {
        ZNGLogVerbose(@"Removed channel %@ from %@", channel.value, [contact fullName]);
        dispatch_semaphore_signal(semaphore);
        success = YES;
    } failure:^(ZNGError * anError) {
        ZNGLogError(@"Unable to remove channel %@ from %@: %@", channel.value, [contact fullName], anError);
        dispatch_semaphore_signal(semaphore);
        success = NO;
        *error = anError;
    }];
    
    long result = dispatch_semaphore_wait(semaphore, semaphoreTimeout);
    return (result == 0) ? success : NO;
}

@end
