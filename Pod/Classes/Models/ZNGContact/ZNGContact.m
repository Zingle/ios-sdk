//
//  ZNGContact.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGContact.h"
#import "ZingleValueTransformers.h"
#import "ZNGContactFieldValue.h"
#import "ZNGLabel.h"
#import "ZNGContactClient.h"
#import "ZNGContactGroup.h"
#import "ZingleSDK.h"
#import "ZNGNewChannel.h"
#import "ZNGAnalytics.h"
#import "ZNGFieldOption.h"
#import "NSString+Initials.h"
#import "ZNGTeam.h"
#import "ZNGUser.h"
#import "ZNGCalendarEvent.h"

@import SBObjectiveCWrapper;

NSString * __nonnull const ZNGContactNotificationSelfMutated = @"ZNGContactNotificationSelfMutated";

static NSString * const ParameterNameStarred = @"is_starred";
static NSString * const ParameterNameConfirmed = @"is_confirmed";
static NSString * const ParameterNameClosed = @"is_closed";

static const NSTimeInterval LateTimeSeconds = 5.0 * 60.0;  // How long before an unconfirmed contact is 'late' (five minutes)

@implementation ZNGContact

- (id) init
{
    self = [super init];
    
    if (self != nil) {
        _channels = @[];
        _customFieldValues = @[];
        _labels = @[];
    }
    
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    NSDictionary * selfAsDictionary = [MTLJSONAdapter JSONDictionaryFromModel:self error:nil];
    ZNGContact * contact = [MTLJSONAdapter modelOfClass:[self class] fromJSONDictionary:selfAsDictionary error:nil];
    contact.contactClient = self.contactClient;
    return contact;
}

#pragma mark - Updating for changes
- (void) updateRemotely
{
    [self.contactClient contactWithId:self.contactId success:^(ZNGContact *contact, ZNGStatus *status) {
        [self updateWithNewData:contact];
    } failure:^(ZNGError *error) {
        SBLogError(@"Unable to refresh contact: %@", error);
    }];
}

- (void) updateWithNewData:(ZNGContact *)contact
{
    if (![self.contactId isEqualToString:contact.contactId]) {
        SBLogError(@"Contact %@ was told to update with a new contact object, but that object has an ID of %@.  Ignoring.", self.contactId, contact.contactId);
        return;
    }
    
    self.customFieldValues = contact.customFieldValues;
    
    if (![self.lastMessage isEqual:contact.lastMessage]) {
        self.lastMessage = contact.lastMessage;
    }
    
    if (![self.channels isEqualToArray:contact.channels]) {
        self.channels = contact.channels;
    } else {
        __block BOOL allChannelsEqual = YES;
        [contact.channels enumerateObjectsUsingBlock:^(ZNGChannel * _Nonnull newChannel, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([newChannel changedSince:self.channels[idx]]) {
                allChannelsEqual = NO;
                *stop = YES;
            }
        }];
        
        if (!allChannelsEqual) {
            self.channels = contact.channels;
            SBLogDebug(@"Updating contact's channels due to one or more mutated channels.");
        }
    }
    
    if (![self.labels isEqualToArray:contact.labels]) {
        self.labels = contact.labels;
    }
    
    if (![self.groups isEqualToArray:contact.groups]) {
        self.groups = contact.groups;
    }
    
    if (![self.updatedAt isEqualToDate:contact.updatedAt]) {
        self.updatedAt = contact.updatedAt;
    }
    
    if (self.isConfirmed != contact.isConfirmed) {
        self.isConfirmed = contact.isConfirmed;
    }
    
    if (![self.assignedToUserId isEqualToString:contact.assignedToUserId]) {
        self.assignedToUserId = contact.assignedToUserId;
    }
    
    if (![self.assignedToTeamId isEqualToString:contact.assignedToTeamId]) {
        self.assignedToTeamId = contact.assignedToTeamId;
    }
}

#pragma mark - Mantle
+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"contactId" : @"id",
             @"isConfirmed" : @"is_confirmed",
             @"isStarred" : @"is_starred",
             @"isClosed" : @"is_closed",
             @"isMessageable" : @"is_messageable",
             @"lockedBySource" : @"locked_by_source",
             @"lastMessage" : @"last_message",
             @"channels" : @"channels",
             @"customFieldValues" : @"custom_field_values",
             @"labels" : @"labels",
             NSStringFromSelector(@selector(groups)): @"contact_groups",
             NSStringFromSelector(@selector(assignedToTeamId)): @"assigned_to_team_id",
             NSStringFromSelector(@selector(assignedToUserId)): @"assigned_to_user_id",
             @"createdAt" : @"created_at",
             @"updatedAt" : @"updated_at",
             NSStringFromSelector(@selector(avatarUri)) : @"avatar_uri",
             NSStringFromSelector(@selector(unconfirmedAt)): @"unconfirmed_at",
             NSStringFromSelector(@selector(calendarEvents)): @"calendar_events",
             };
}

- (NSUInteger) hash
{
    return [self.contactId hash];
}

- (BOOL) isEqual:(id)other
{
    if (![other isKindOfClass:[ZNGContact class]]) {
        return NO;
    }
    
    return [self isEqualToContact:other];
}

- (BOOL) isEqualToContact:(ZNGContact *)other
{
    return ([self.contactId isEqualToString:other.contactId]);
}

+ (NSValueTransformer*)lastMessageJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ZNGMessage class]];
}

+ (NSValueTransformer*)channelsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGChannel class]];
}

+ (NSValueTransformer*)customFieldValuesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGContactFieldValue class]];
}

+ (NSValueTransformer*)labelsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGLabel class]];
}

+ (NSValueTransformer *) groupsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGContactGroup class]];
}

+ (NSValueTransformer *)calendarEventsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGCalendarEvent class]];
}

+ (NSValueTransformer*)createdAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer*)updatedAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer *)unconfirmedAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer *) avatarUriJSONTransformer
{
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

-(ZNGContactFieldValue *)titleFieldValue
{
    for (ZNGContactFieldValue *fieldValue in self.customFieldValues) {
        if ([fieldValue.customField.displayName isEqualToString:@"Title"]) {
            return fieldValue;
        }
    }
    
    return nil;
}

-(ZNGContactFieldValue *)firstNameFieldValue
{
    for (ZNGContactFieldValue *fieldValue in self.customFieldValues) {
        if ([fieldValue.customField.displayName isEqualToString:@"First Name"]) {
            return fieldValue;
        }
    }
    
    return nil;
}

-(ZNGContactFieldValue *)lastNameFieldValue
{
    for (ZNGContactFieldValue *fieldValue in self.customFieldValues) {
        if ([fieldValue.customField.displayName isEqualToString:@"Last Name"]) {
            return fieldValue;
        }
    }
    
    return nil;
}

-(nullable ZNGContactFieldValue *)roomFieldValue
{
    NSUInteger index = [self.customFieldValues indexOfObjectPassingTest:^BOOL(ZNGContactFieldValue * fieldValue, NSUInteger idx, BOOL * _Nonnull stop) {
        return [fieldValue.customField.code isEqualToString:@"room"];
    }];
    
    return (index != NSNotFound) ? self.customFieldValues[index] : nil;
}

- (nullable ZNGContactFieldValue *) contactFieldValueForType:(ZNGContactField *)field
{
    for (ZNGContactFieldValue * value in self.customFieldValues) {
        if ([value.customField isEqual:field]) {
            return value;
        }
    }
    
    return nil;
}

- (ZNGChannel *)channelOfType:(ZNGChannelType *)type
{
    for (ZNGChannel * channel in self.channels) {
        if ([channel.channelType isEqual:type]) {
            return channel;
        }
    }
    
    return nil;
}

-(ZNGChannel *)phoneNumberChannel
{
    ZNGChannel * channel = nil;
    
    // Attempt to find a default phone number channel.  If that fails, we will return the first phone number.
    for (ZNGChannel * testChannel in [self.channels reverseObjectEnumerator]) {
        if ([testChannel.channelType.typeClass isEqualToString:@"PhoneNumber"]) {
            channel = testChannel;
            
            if (testChannel.isDefaultForType) {
                return testChannel;
            }
        }
    }

    return channel;
}

- (nullable ZNGChannel *)defaultChannel
{
    // If they only have one (or zero) channel, this is an easy decision!
    if ([self.channels count] <= 1) {
        return [self.channels firstObject];
    }
    
    // Is there a default channel?
    for (ZNGChannel * channel in self.channels) {
        if (channel.isDefault) {
            return channel;
        }
    }
    
    return nil;
}

- (NSString *)fullNameUsingUnformattedPhoneNumberValue:(BOOL)unformattedPhoneNumber
{
    NSString *title = [[self titleFieldValue] value];
    NSString *firstName = [[self firstNameFieldValue] value];
    NSString *lastName = [[self lastNameFieldValue] value];
    
    if ([firstName length] + [lastName length] == 0) {
        ZNGChannel * phoneChannel = [self phoneNumberChannel];
        
        if (phoneChannel != nil) {
            if (unformattedPhoneNumber) {
                return [phoneChannel displayValueUsingRawValue];
            }
            
            return [phoneChannel displayValueUsingFormattedValue];
        }

        return @"Anonymous User";
    } else {
        NSMutableString * name = [[NSMutableString alloc] init];
        
        if ([title length] > 0)
        {
            [name appendFormat:@"%@ ", title];
        }
        
        if ([firstName length] > 0)
        {
            [name appendFormat:@"%@ ", firstName];
        }
        
        if ([lastName length] > 0)
        {
            [name appendString:lastName];
        }
        
        return [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
}

- (NSString *)fullName
{
    return [self fullNameUsingUnformattedPhoneNumberValue:NO];
}

- (NSString *) initials
{
    NSString * firstName = [[self firstNameFieldValue] value] ?: @"";
    NSString * lastName = [[self lastNameFieldValue] value] ?: @"";
    NSString * name = [[NSString stringWithFormat:@"%@ %@", firstName, lastName] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([name length] == 0) {
        return nil;
    }
    
    return [name initials];
}

- (NSArray<ZNGCalendarEvent *> *) pastCalendarEvents
{
    if (self.calendarEvents == nil) {
        return nil;
    }
    
    NSMutableArray<ZNGCalendarEvent *> * events = [[NSMutableArray alloc] init];
    NSDate * now = [NSDate date];
    
    for (ZNGCalendarEvent * event in self.calendarEvents) {
        if (event.endsAt == nil) {
            SBLogWarning(@"%@ (%@) event has no \"ends_at\" timestamp.", event.title, event.calendarEventId);
            continue;
        }
        
        NSTimeInterval timeSinceEnd = [now timeIntervalSinceDate:event.endsAt];
        
        if (timeSinceEnd > 0.0) {
            [events addObject:event];
        }
    }
    
    return events;
}

- (NSArray<ZNGCalendarEvent *> *) ongoingCalendarEvents
{
    if (self.calendarEvents == nil) {
        return nil;
    }
    
    NSMutableArray<ZNGCalendarEvent *> * events = [[NSMutableArray alloc] init];
    NSDate * now = [NSDate date];
    
    for (ZNGCalendarEvent * event in self.calendarEvents) {
        if ((event.endsAt == nil) || (event.startsAt == nil)) {
            SBLogWarning(@"%@ (%@) event is missing either \"starts_at\" or \"ends_at.\"", event.title, event.calendarEventId);
            continue;
        }
        
        NSTimeInterval timeSinceStart = [now timeIntervalSinceDate:event.startsAt];
        NSTimeInterval timeSinceEnd = [now timeIntervalSinceDate:event.endsAt];
        
        if ((timeSinceStart > 0.0) && (timeSinceEnd < 0.0)) {
            [events addObject:event];
        }
    }
    
    return events;
}

- (NSArray<ZNGCalendarEvent *> *) futureCalendarEvents
{
    if (self.calendarEvents == nil) {
        return nil;
    }
    
    NSMutableArray<ZNGCalendarEvent *> * events = [[NSMutableArray alloc] init];
    NSDate * now = [NSDate date];
    
    for (ZNGCalendarEvent * event in self.calendarEvents) {
        if (event.startsAt == nil) {
            SBLogWarning(@"%@ (%@) event has no \"starts_at\" timestamp.", event.title, event.calendarEventId);
            continue;
        }
        
        NSTimeInterval timeSinceStart = [now timeIntervalSinceDate:event.startsAt];
        
        if (timeSinceStart < 0.0) {
            [events addObject:event];
        }
    }
    
    return events;
}

- (NSArray<ZNGChannel *> *) channelsWithValues
{
    NSMutableArray<ZNGChannel *> * populatedChannels = [[NSMutableArray alloc] initWithCapacity:[self.channels count]];
    
    for (ZNGChannel * channel in self.channels) {
        if (([channel.value length] > 0) || ([channel.formattedValue length] > 0)) {
            [populatedChannels addObject:channel];
        }
    }
    
    return populatedChannels;
}

- (NSArray<ZNGContactFieldValue *> *) customFieldsWithValues
{
    NSMutableArray<ZNGContactFieldValue *> * values = [[NSMutableArray alloc] initWithCapacity:[self.customFieldValues count]];
    
    for (ZNGContactFieldValue * value in self.customFieldValues) {
        if ([value.value length] > 0) {
            [values addObject:value];
        }
    }
    
    return values;
}

- (NSArray<ZNGNewContactFieldValue *> *) customFieldsWithValuesAsNewValueObjects
{
    NSArray<ZNGContactFieldValue *> * customFields = [self customFieldsWithValues];
    NSMutableArray<ZNGNewContactFieldValue *> * values = [[NSMutableArray alloc] initWithCapacity:[customFields count]];
    
    for (ZNGContactFieldValue * customField in customFields) {
        // Check if it is editable
        if ([self editingCustomFieldIsLocked:customField]) {
            continue;
        }
        
        ZNGNewContactFieldValue * newValue = [[ZNGNewContactFieldValue alloc] init];
        newValue.value = customField.value;
        newValue.customFieldOptionId = customField.selectedCustomFieldOptionId;
        newValue.customFieldId = customField.customField.contactFieldId;
        [values addObject:newValue];
    }
    
    return values;
}

- (NSArray<ZNGNewContactFieldValue *> *) customFieldsDeletedSince:(ZNGContact *)oldContact
{
    NSMutableArray<ZNGNewContactFieldValue *> * deletedFields = [[NSMutableArray alloc] init];
    NSArray<ZNGContactFieldValue *> * currentValues = [self customFieldsWithValues];
    NSArray<ZNGContactFieldValue *> * oldValues = [oldContact customFieldsWithValues];
    
    for (ZNGContactFieldValue * oldValue in oldValues) {
        BOOL foundCurrentValue = NO;
        ZNGContactField * oldField = oldValue.customField;
        
        for (ZNGContactFieldValue * currentValue in currentValues) {
            if ([currentValue.customField.contactFieldId isEqualToString:oldField.contactFieldId]) {
                foundCurrentValue = YES;
                break;
            }
        }
        
        if (!foundCurrentValue) {
            // This value is being removed.
            ZNGNewContactFieldValue * deletedField = [[ZNGNewContactFieldValue alloc] init];
            deletedField.customFieldId = oldField.contactFieldId;
            deletedField.value = @"";
            
            // If this is a single selection type object, we will check for an empty selection.
            if ([oldField.dataType isEqualToString:ZNGContactFieldDataTypeSingleSelect]) {
                for (ZNGFieldOption * option in oldField.options) {
                    if ([[option.value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
                        deletedField.customFieldOptionId = option.optionId;
                        break;
                    }
                }
            }
            
            [deletedFields addObject:deletedField];
        }
    }
    
    return deletedFields;
}

- (BOOL) changedSince:(nullable ZNGContact *)old
{
    // Group changes are not reflected in the updatedAt timestamp, so that must be checked explicitly
    NSSet * groupSet = [NSSet setWithArray:self.groups];
    NSSet * oldGroupSet = [NSSet setWithArray:old.groups];
    
    if (![groupSet isEqualToSet:oldGroupSet]) {
        return YES;
    }
    
    if ((old.updatedAt == nil) || (self.updatedAt == nil)) {
        return YES;
    }
    
    BOOL hasEvents = ((self.calendarEvents != nil) || (old.calendarEvents != nil));
    
    if (hasEvents) {
        BOOL onlyOneHasEvents = (!!self.calendarEvents != !!old.calendarEvents);

        if (onlyOneHasEvents) {
            return YES;
        }
        
        if (![self.calendarEvents isEqualToArray:old.calendarEvents]) {
            return YES;
        }
    }
    
    if (![old.contactId isEqualToString:self.contactId]) {
        SBLogError(@"%@ is being checked against %@ as if they were the same contact, but they have different IDs (%@ vs. %@).", [old fullName], [self fullName], old.contactId, self.contactId);
        return NO;
    }
    
    NSTimeInterval timeBetweenUpdates = [self.updatedAt timeIntervalSinceDate:old.updatedAt];
    return (timeBetweenUpdates > 0.0);
}

- (BOOL) hasBeenEditedSince:(ZNGContact *)old
{
    if (old == nil) {
        return YES;
    }
    
    NSSet * customFieldSet = [NSSet setWithArray:[self customFieldsWithValues]];
    NSSet * oldCustomFieldSet = [NSSet setWithArray:[old customFieldsWithValues]];
    BOOL sameCustomFields = [customFieldSet isEqualToSet:oldCustomFieldSet];
    
    NSSet * channelsSet = [NSSet setWithArray:[self channelsWithValues]];
    NSSet * oldChannelsSet = [NSSet setWithArray:[old channelsWithValues]];
    __block BOOL sameChannels = [channelsSet isEqualToSet:oldChannelsSet];
    BOOL sameConfirmed = (old.isConfirmed == self.isConfirmed);
    
    NSSet * labelsSet = [NSSet setWithArray:self.labels];
    NSSet * oldLabelsSet = [NSSet setWithArray:old.labels];
    BOOL sameLabels = ([labelsSet isEqualToSet:oldLabelsSet]);
    
    NSSet * groupsSet = [NSSet setWithArray:self.groups];
    NSSet * oldGroupsSet = [NSSet setWithArray:old.groups];
    BOOL sameGroups = ([groupsSet isEqualToSet:oldGroupsSet]);
    
    if (sameChannels) {
        // We have the same channel IDs, but some of the channels may be changed
        [[self channelsWithValues] enumerateObjectsUsingBlock:^(ZNGChannel * _Nonnull channel, NSUInteger idx, BOOL * _Nonnull stop) {
            NSUInteger oldChannelIndex = [old.channels indexOfObject:channel];
            
            if ([channel changedSince:old.channels[oldChannelIndex]]) {
                sameChannels = NO;
                *stop = YES;
            }
        }];
    }
    
    BOOL sameAssignment = (![self assignmentHasChangedSince:old]);

    return (!sameCustomFields || !sameChannels || !sameConfirmed || !sameLabels || !sameGroups || !sameAssignment);
}

- (BOOL) assignmentHasChangedSince:(ZNGContact *)old
{
    BOOL userAssignmentAlwaysNil = ((self.assignedToUserId == nil) && (old.assignedToUserId == nil));
    BOOL teamAssignmentAlwaysNil = ((self.assignedToTeamId == nil) && (old.assignedToTeamId == nil));
    BOOL userAssignmentEqual = ((userAssignmentAlwaysNil) || ([self.assignedToUserId isEqualToString:old.assignedToUserId]));
    BOOL teamAssignmentEqual = ((teamAssignmentAlwaysNil) || ([self.assignedToTeamId isEqualToString:old.assignedToTeamId]));
    
    return ((!userAssignmentEqual) || (!teamAssignmentEqual));
}

- (BOOL) visualRefreshSinceOldMessageShouldAnimate:(ZNGContact *)old
{
    return (![old.lastMessage isEqual:self.lastMessage]);
}

- (NSArray<NSString *> *) _customFieldDisplayNamesLockedWhenContactLockedBySource
{
    return @[
              @"Title",
              @"First Name",
              @"Last Name",
              @"Room",
              @"Checkin Date",
              @"Checkout Date"
              ];
}

- (BOOL) editingCustomFieldIsLocked:(ZNGContactFieldValue *)customField
{
    if ([self.lockedBySource length] > 0) {
        NSArray<NSString *> * lockedDisplayNames = [self _customFieldDisplayNamesLockedWhenContactLockedBySource];
        return [lockedDisplayNames containsObject:customField.customField.displayName];
    }
    
    return NO;
}

- (BOOL) editingChannelIsLocked:(ZNGChannel *)channel
{
    // If the contact is locked by source, the user cannot edit the email nor phone number channels
    if ([self.lockedBySource length] > 0) {
        return ([channel isPhoneNumber] || [channel isEmail]);
    }
    
    return NO;
}

- (NSDate *) lateUnconfirmedTime
{
    // If the API is up to date and has the newer unconfirmed_at date, use that; otherwise default to
    //  the old behavior and use the timestamp of the last message
    NSDate * lateDate = self.unconfirmedAt ?: self.lastMessage.createdAt;
    
    if (lateDate == nil) {
        return nil;
    }
    
    return [lateDate dateByAddingTimeInterval:LateTimeSeconds];
}

#pragma mark - Mutators
- (void) confirm
{
    [self confirmWithCompletion:nil];
}

- (void) unconfirm
{
    [self unconfirmWithCompletion:nil];
}

- (void) _setConfirmed:(BOOL)isConfirmed completion:(void (^_Nullable)(BOOL succeeded))completion
{
    BOOL oldValue = self.isConfirmed;
    
    // We have to explicitly use @YES/@NO instead of autoboxing with @(isStarred) because a certain very particular Jovin server explodes if it gets a 1 for a boolean
    NSNumber * confirmedNumber = isConfirmed ? @YES : @NO;
    NSDictionary * params = @{ ParameterNameConfirmed : confirmedNumber };
    
    self.isConfirmed = isConfirmed;
    [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];
    
    [self.contactClient updateContactWithId:self.contactId withParameters:params success:^(ZNGContact *contact, ZNGStatus *status) {
        if (contact.isConfirmed != isConfirmed) {
            SBLogError(@"Our POST to set isConfirmed to %@ succeeded, but the contact returned by the server is still %@",
                        (isConfirmed) ? @"YES" : @"NO",
                        (contact.isConfirmed) ? @"confirmed" : @"not confirmed");
        }
        
        self.isConfirmed = contact.isConfirmed;
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];
        
        if (completion != nil) {
            completion(YES);
        }
    } failure:^(ZNGError *error) {
        SBLogError(@"Failed to update contact %@: %@", self.contactId, error);

        self.isConfirmed = oldValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];
        
        if (completion != nil) {
            completion(NO);
        }
    }];
}

- (void) close
{
    [self _setClosed:YES completion:nil];
}

- (void) reopen
{
    [self _setClosed:NO completion:nil];
}

- (void) _setClosed:(BOOL)isClosed completion:(void (^_Nullable)(BOOL succeeded))completion
{
    BOOL oldClosed = self.isClosed;
    BOOL oldConfirmed = self.isConfirmed;
    
    NSNumber * closed = isClosed ? @YES : @NO;
    NSDictionary * params = @{ ParameterNameClosed : closed };
    
    self.isClosed = isClosed;
    
    // Per MOBILE-371, closing an unconfirmed conversation should confirm the conversation
    if (isClosed && !self.isConfirmed) {
        SBLogInfo(@"Closing an unconfirmed contact.  This contact will be confirmed at the same time.");
        
        NSMutableDictionary * mutableParams = [params mutableCopy];
        mutableParams[ParameterNameConfirmed] = @YES;
        params = mutableParams;
        
        self.isConfirmed = YES;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];
    
    [self.contactClient updateContactWithId:self.contactId withParameters:params success:^(ZNGContact *contact, ZNGStatus *status) {
        if (contact.isClosed != isClosed) {
            SBLogError(@"Our POST to set isClosed to %@ succeeded, but the contact returned by the server is still %@",
                        (isClosed) ? @"YES" : @"NO",
                        (contact.isClosed) ? @"closed" : @"open");
        }
        
        self.isClosed = contact.isClosed;
        self.isConfirmed = contact.isConfirmed;
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];
        
        if (completion != nil) {
            completion(YES);
        }
    } failure:^(ZNGError *error) {
        SBLogError(@"Unable to update %@'s closed status: %@", [self fullName], error);
        
        self.isClosed = oldClosed;
        self.isConfirmed = oldConfirmed;
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];
        
        if (completion != nil) {
            completion(NO);
        }
    }];
}

- (void) closeWithCompletion:(void (^_Nullable)(BOOL succeeded))completion
{
    [self _setClosed:YES completion:completion];
}

- (void) reopenWithCompletion:(void (^_Nullable)(BOOL succeeded))completion
{
    [self _setClosed:NO completion:completion];
}

- (void) confirmWithCompletion:(void (^_Nullable)(BOOL succeeded))completion
{
    [self _setConfirmed:YES completion:completion];
}

- (void) unconfirmWithCompletion:(void (^_Nullable)(BOOL succeeded))completion
{
    [self _setConfirmed:NO completion:completion];
}

- (void) assignToTeamWithId:(NSString *)teamId
{
    if ([teamId length] == 0) {
        SBLogError(@"%s called with no team ID.  Ignoring.", __PRETTY_FUNCTION__);
        return;
    }
    
    NSString * oldTeamId = self.assignedToTeamId;
    NSString * oldUserId = self.assignedToUserId;
    
    [self _atomicallySetAssignedTeamId:teamId andUserId:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];

    [self.contactClient assignContactWithId:self.contactId toTeamId:teamId success:^(ZNGContact *contact, ZNGStatus *status) {
        // We succeeded, so we expect these to match what we set.  Just in case, we'll double set the values.
        [self _atomicallySetAssignedTeamId:contact.assignedToTeamId andUserId:contact.assignedToUserId];
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];
    } failure:^(ZNGError *error) {
        SBLogError(@"Assigning contact %@ to team %@ failed: %@", [self fullName], teamId, error);
        
        [self _atomicallySetAssignedTeamId:oldTeamId andUserId:oldUserId];
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];
    }];
}

- (void) assignToUserWithId:(NSString *)userId
{
    if ([userId length] == 0) {
        SBLogError(@"%s called with no user ID.  Ignoring.", __PRETTY_FUNCTION__);
        return;
    }
    
    NSString * oldTeamId = self.assignedToTeamId;
    NSString * oldUserId = self.assignedToUserId;

    [self _atomicallySetAssignedTeamId:nil andUserId:userId];
    [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];
    
    [self.contactClient assignContactWithId:self.contactId toUserId:userId success:^(ZNGContact *contact, ZNGStatus *status) {
        // We succeeded, so we expect these to match what we set.  Just in case, we'll double set the values.
        [self _atomicallySetAssignedTeamId:contact.assignedToTeamId andUserId:contact.assignedToUserId];
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];
    } failure:^(ZNGError *error) {
        SBLogError(@"Assigning contact %@ to user %@ failed: %@", [self fullName], userId, error);
        
        [self _atomicallySetAssignedTeamId:oldTeamId andUserId:oldUserId];
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];
    }];
}

- (void) unassign
{
    NSString * oldTeamId = self.assignedToTeamId;
    NSString * oldUserId = self.assignedToUserId;
    
    [self _atomicallySetAssignedTeamId:nil andUserId:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];

    [self.contactClient unassignContactWithId:self.contactId success:nil failure:^(ZNGError *error) {
        SBLogError(@"Unassigning contact %@ failed: %@", [self fullName], error);
        
        [self _atomicallySetAssignedTeamId:oldTeamId andUserId:oldUserId];
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];
    }];
}

- (void) _atomicallySetAssignedTeamId:(NSString *)teamId andUserId:(NSString *)userId
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(assignedToTeamId))];
    [self willChangeValueForKey:NSStringFromSelector(@selector(assignedToUserId))];
    _assignedToTeamId = teamId;
    _assignedToUserId = userId;
    [self didChangeValueForKey:NSStringFromSelector(@selector(assignedToUserId))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(assignedToTeamId))];
}

@end
