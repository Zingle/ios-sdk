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

static const int zngLogLevel = ZNGLogLevelWarning;

NSString * __nonnull const ZNGContactNotificationSelfMutated = @"ZNGContactNotificationSelfMutated";

static NSString * const ParameterNameStarred = @"is_starred";
static NSString * const ParameterNameConfirmed = @"is_confirmed";

@implementation ZNGContact

- (id) initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self != nil) {
        [self setupObservation];
    }
    
    return self;
}

- (id) initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    
    if (self != nil) {
        [self setupObservation];
    }
    
    return self;
}

- (void) setupObservation
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyPushNotificationReceived:) name:ZNGPushNotificationReceived object:nil];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Observing for changes
-(void) notifyPushNotificationReceived:(NSNotification *)notification
{
    NSString * updatedContactId = notification.userInfo[@"feedId"];
    
    if ([self.contactId isEqualToString:updatedContactId]) {
        // We may have been updated.
        
        [self.contactClient contactWithId:self.contactId success:^(ZNGContact *contact, ZNGStatus *status) {
            
            if (![contact requiresVisualRefeshSince:self]) {
                // Nothing significant has changed
                return;
            }
            
            if (![[self fullName] isEqualToString:[contact fullName]]) {
                self.customFieldValues = contact.customFieldValues;
            }
            
            if (![self.lastMessage isEqual:contact.lastMessage]) {
                self.lastMessage = contact.lastMessage;
            }
            
            if (![self.channels isEqualToArray:contact.channels]) {
                self.channels = contact.channels;
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
            
        } failure:nil];
        
    }
}

#pragma mark - Mantle
+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"contactId" : @"id",
             @"isConfirmed" : @"is_confirmed",
             @"isStarred" : @"is_starred",
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

-(ZNGChannel *)phoneNumberChannel
{
    for (ZNGChannel *channel in self.channels) {
        if ([channel.channelType.typeClass isEqualToString:@"PhoneNumber"]) {
            return channel;
        }
    }
    return nil;
}

- (ZNGChannel *)channelForFreshOutgoingMessage
{
    if (self.lastMessage != nil) {
        // We have a message to or from this person.  Let's return that same channel if we have any channel info.
        
        // Outgoing or incoming?
        ZNGCorrespondent * dude = ([self.lastMessage isOutbound]) ? self.lastMessage.recipient : self.lastMessage.sender;
        
        if (dude.channel != nil) {
            return dude.channel;
        }
    }
    
    
    // We resort to finding a phone number channel if possible
    ZNGChannel * phoneChannel = nil;
    
    for (ZNGChannel * channel in self.channels) {
        if ([channel.channelType.typeClass isEqualToString:@"PhoneNumber"]) {
            phoneChannel = channel;
            
            if (phoneChannel.isDefaultForType) {
                return phoneChannel;
            }
        }
    }
    
    return phoneChannel;
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
        return name;
    }
}

- (BOOL)requiresVisualRefeshSince:(ZNGContact *)old
{
    BOOL sameLastMessage = ([old.lastMessage isEqual:self.lastMessage]);
    BOOL sameName = ([[old fullName] isEqualToString:[self fullName]]);
    BOOL sameStarConfirmed = ((old.isStarred == self.isStarred) && (old.isConfirmed == self.isConfirmed));
    BOOL sameLabels = ([old.labels isEqualToArray:self.labels]);
    
    return !(sameLastMessage && sameName && sameStarConfirmed && sameLabels);
}

- (BOOL) visualRefreshSinceOldMessageShouldAnimate:(ZNGContact *)old
{
    return (![old.lastMessage isEqual:self.lastMessage]);
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
