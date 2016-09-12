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
#import "ZNGLogging.h"
#import "ZingleSDK.h"
#import "ZNGNewChannel.h"
#import "ZNGAnalytics.h"

static const int zngLogLevel = ZNGLogLevelDebug;

NSString * __nonnull const ZNGContactNotificationSelfMutated = @"ZNGContactNotificationSelfMutated";

static NSString * const ParameterNameStarred = @"is_starred";
static NSString * const ParameterNameConfirmed = @"is_confirmed";

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


#pragma mark - Updating for changes
- (void) updateRemotely
{
    [self.contactClient contactWithId:self.contactId success:^(ZNGContact *contact, ZNGStatus *status) {
        if (![[self fullName] isEqualToString:[contact fullName]]) {
            self.customFieldValues = contact.customFieldValues;
        }
        
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
                ZNGLogDebug(@"Updating contact's channels due to one or more mutated channels.");
            }
        }
        
        if (![self.labels isEqualToArray:contact.labels]) {
            self.labels = contact.labels;
        }
        
        if (![self.updatedAt isEqualToDate:contact.updatedAt]) {
            self.updatedAt = contact.updatedAt;
        }
        
        if (self.isConfirmed != contact.isConfirmed) {
            self.isConfirmed = contact.isConfirmed;
        }
        
        if (self.isStarred != contact.isStarred) {
            self.isStarred = contact.isStarred;
        }
        
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Unable to refresh contact: %@", error);
    }];
}

#pragma mark - Mantle
+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"contactId" : @"id",
             @"isConfirmed" : @"is_confirmed",
             @"isStarred" : @"is_starred",
             @"lockedBySource" : @"locked_by_source",
             @"lastMessage" : @"last_message",
             @"channels" : @"channels",
             @"customFieldValues" : @"custom_field_values",
             @"labels" : @"labels",
             @"createdAt" : @"created_at",
             @"updatedAt" : @"udpated_at"
             };
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
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGMessage.class];
}

+ (NSValueTransformer*)channelsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGChannel.class];
}

+ (NSValueTransformer*)customFieldValuesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGContactFieldValue.class];
}

+ (NSValueTransformer*)labelsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGLabel.class];
}

+ (NSValueTransformer*)createdAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer*)updatedAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

-(ZNGContactFieldValue *)titleFieldValue
{
    for (ZNGContactFieldValue *fieldValue in self.customFieldValues) {
        if ([fieldValue.customField.displayName isEqualToString:@"Title"]) {
            return fieldValue;
        }
    }
    ZNGContactFieldValue *fieldValue = [[ZNGContactFieldValue alloc] init];
    fieldValue.customField = [[ZNGContactField alloc] init];
    fieldValue.customField.displayName = @"Title";
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.customFieldValues];
    [array addObject:fieldValue];
    self.customFieldValues = array;
    return fieldValue;
}

-(ZNGContactFieldValue *)firstNameFieldValue
{
    for (ZNGContactFieldValue *fieldValue in self.customFieldValues) {
        if ([fieldValue.customField.displayName isEqualToString:@"First Name"]) {
            return fieldValue;
        }
    }
    ZNGContactFieldValue *fieldValue = [[ZNGContactFieldValue alloc] init];
    fieldValue.customField = [[ZNGContactField alloc] init];
    fieldValue.customField.displayName = @"First Name";
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.customFieldValues];
    [array addObject:fieldValue];
    self.customFieldValues = array;
    return fieldValue;
}

-(ZNGContactFieldValue *)lastNameFieldValue
{
    for (ZNGContactFieldValue *fieldValue in self.customFieldValues) {
        if ([fieldValue.customField.displayName isEqualToString:@"Last Name"]) {
            return fieldValue;
        }
    }
    ZNGContactFieldValue *fieldValue = [[ZNGContactFieldValue alloc] init];
    fieldValue.customField = [[ZNGContactField alloc] init];
    fieldValue.customField.displayName = @"Last Name";
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.customFieldValues];
    [array addObject:fieldValue];
    self.customFieldValues = array;
    return fieldValue;
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

- (NSString *)fullName
{
    NSString *title = [self titleFieldValue].value;
    NSString *firstName = [self firstNameFieldValue].value;
    NSString *lastName = [self lastNameFieldValue].value;
    
    if(firstName.length < 1 && lastName.length < 1)
    {
        NSString *phoneNumber = [self phoneNumberChannel].formattedValue;
        if (phoneNumber) {
            return phoneNumber;
        } else {
            return @"Anonymous User";
        }
    }
    else
    {
        NSString *name = @"";
        
        if(title.length > 0)
        {
            name = [name stringByAppendingString:[NSString stringWithFormat:@"%@ ", title]];
        }
        if(firstName.length > 0)
        {
            name = [name stringByAppendingString:[NSString stringWithFormat:@"%@ ", firstName]];
        }
        if(lastName.length > 0)
        {
            name = [name stringByAppendingString:lastName];
        }
        return [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
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
        ZNGNewContactFieldValue * newValue = [[ZNGNewContactFieldValue alloc] init];
        newValue.value = customField.value;
        newValue.customFieldOptionId = customField.selectedCustomFieldOptionId;
        newValue.customFieldId = customField.customField.contactFieldId;
        [values addObject:newValue];
    }
    
    return values;
}

- (BOOL)requiresVisualRefeshSince:(ZNGContact *)old
{
    BOOL sameLastMessage = ([old.lastMessage isEqual:self.lastMessage]);
    BOOL sameName = ([[old fullName] isEqualToString:[self fullName]]);
    BOOL sameStarConfirmed = ((old.isStarred == self.isStarred) && (old.isConfirmed == self.isConfirmed));
    BOOL sameLabels = ([old.labels isEqualToArray:self.labels]);
    
    return !(sameLastMessage && sameName && sameStarConfirmed && sameLabels);
}

- (BOOL) hasBeenEditedSince:(ZNGContact *)old
{
    if (old == nil) {
        return YES;
    }
    
    BOOL sameCustomFields = [[self customFieldsWithValues] isEqualToArray:[old customFieldsWithValues]];
    __block BOOL sameChannels = [[self channelsWithValues] isEqualToArray:[old channelsWithValues]];
    BOOL sameStarConfirmed = ((old.isStarred == self.isStarred) && (old.isConfirmed == self.isConfirmed));
    BOOL sameLabels = ([old.labels isEqualToArray:self.labels]);
    
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

    return (!sameCustomFields || !sameChannels || !sameStarConfirmed || !sameLabels);
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

#pragma mark - Mutators
- (void) star
{
    [self _setStar:YES];
}

- (void) unstar
{
    [self _setStar:NO];
}

- (void) _setStar:(BOOL)isStarred
{
    // We have to explicitly use @YES/@NO instead of autoboxing with @(isStarred) because a certain very particular Jovin server explodes if it gets a 1 for a boolean
    NSNumber * starredNumber = isStarred ? @YES : @NO;
    NSDictionary * params = @{ ParameterNameStarred : starredNumber };
    
    [self.contactClient updateContactWithId:self.contactId withParameters:params
                                    success:^(ZNGContact *contact, ZNGStatus *status) {
                                        
                                        if (contact.isStarred != isStarred) {
                                            ZNGLogError(@"Our POST to set isStarred to %@ succeeded, but the contact returned by the server is still %@",
                                                        (isStarred) ? @"YES" : @"NO",
                                                        (contact.isStarred) ? @"starred" : @"not starred");
                                        }
                                        
                                        self.isStarred = contact.isStarred;
                                        [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];
                                        
                                        if (contact.isStarred) {
                                            [[ZNGAnalytics sharedAnalytics] trackStarredContact:self];
                                        } else {
                                            [[ZNGAnalytics sharedAnalytics] trackUnstarredContact:self];
                                        }
                                        
                                    } failure:^(ZNGError *error) {
                                        ZNGLogError(@"Failed to update contact %@: %@", self.contactId, error);
                                    }];
}

- (void) confirm
{
    [self _setConfirmed:YES];
}

- (void) unconfirm
{
    [self _setConfirmed:NO];
}

- (void) _setConfirmed:(BOOL)isConfirmed
{
    // We have to explicitly use @YES/@NO instead of autoboxing with @(isStarred) because a certain very particular Jovin server explodes if it gets a 1 for a boolean
    NSNumber * confirmedNumber = isConfirmed ? @YES : @NO;
    NSDictionary * params = @{ ParameterNameConfirmed : confirmedNumber };
    
    [self.contactClient updateContactWithId:self.contactId withParameters:params success:^(ZNGContact *contact, ZNGStatus *status) {
        
        if (contact.isConfirmed != isConfirmed) {
            ZNGLogError(@"Our POST to set isConfirmed to %@ succeeded, but the contact returned by the server is still %@",
                        (isConfirmed) ? @"YES" : @"NO",
                        (contact.isConfirmed) ? @"confirmed" : @"not confirmed");
        }
        
        self.isConfirmed = contact.isConfirmed;
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNGContactNotificationSelfMutated object:self];
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Failed to update contact %@: %@", self.contactId, error);
    }];
}

@end
