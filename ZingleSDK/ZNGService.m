//
//  ZNGService.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGService.h"
#import "ZingleModel.h"
#import "ZingleDAO.h"
#import "ZingleSDK.h"
#import "NSMutableDictionary+json.h"
#import "ZingleModelSearch.h"
#import "ZNGPlan.h"
#import "ZNGContact.h"
#import "ZNGAddress.h"
#import "ZNGContactChannel.h"
#import "ZNGServiceChannel.h"
#import "ZNGChannelType.h"
#import "ZNGLabelSearch.h"
#import "ZNGContactSearch.h"
#import "ZNGContactCustomFieldSearch.h"
#import "ZNGMessageSearch.h"
#import "ZNGAutomationSearch.h"
#import "ZNGWebServiceLogSearch.h"
#import "ZNGAvailablePhoneNumberSearch.h"
#import "ZNGAvailablePhoneNumber.h"
#import "ZNGAccount.h"
#import "ZNGServiceSettingsSearch.h"
#import "ZNGChannelType.h"
#import "ZNGLabel.h"
#import "ZNGCustomField.h"
#import "ZNGMessage.h"

@implementation ZNGService

- (id)init
{
    if( self = [super init] ) {
        [self initDefaults];
    }
    return self;
}

- (id)initWithAccount:(ZNGAccount *)account
{
    if( self = [super init] )
    {
        self.account = account;
        [self initDefaults];
    }
    
    return self;
}

- (void)initDefaults
{
    self.displayName = @"";
    self.timeZone = @"";
    self.address = [[ZNGAddress alloc] init];
    self.channels = [NSMutableArray array];
    self.channelTypes = [NSMutableArray array];
}

- (NSString *)baseURIWithID:(BOOL)withID
{
    if( withID ) {
        return [NSString stringWithFormat:@"services/%@", self.ID];
    } else {
        return @"services";
    }
}

- (void)hydrate:(NSMutableDictionary *)data
{
    [self hydrateDates:data];
    
    self.ID = [data objectAtPath:@"id" expectedClass:[NSString class] default:nil];
    
    NSMutableDictionary *accountData = [data objectAtPath:@"account" expectedClass:[NSDictionary class] default:[NSMutableDictionary dictionary]];
    self.account = [[ZNGAccount alloc] init];
    [self.account hydrate:accountData];
    
    self.displayName = [data objectAtPath:@"display_name" expectedClass:[NSString class] default:@""];
    self.timeZone = [data objectAtPath:@"time_zone" expectedClass:[NSString class] default:@""];
    
    self.plan = [[ZNGPlan alloc] init];
    NSMutableDictionary *planData = [[data objectAtPath:@"plan" expectedClass:[NSDictionary class] default:[NSMutableDictionary dictionary]] mutableCopy];
    [self.plan hydrate:planData];
    
    self.address = [[ZNGAddress alloc] init];
    NSMutableDictionary *addressData = [[data objectAtPath:@"service_address" expectedClass:[NSDictionary class] default:[NSMutableDictionary dictionary]] mutableCopy];
    [self.address hydrate:addressData];
    
    NSArray *channels = [data objectAtPath:@"channels" expectedClass:[NSArray class] default:[NSArray array]];
    
    self.channels = [NSMutableArray array];
    for( NSMutableDictionary *channelData in channels )
    {
        ZNGServiceChannel *channel = [[ZNGServiceChannel alloc] initWithService:self];
        [channel hydrate:[channelData mutableCopy]];
        [self.channels addObject:channel];
    }
    
    NSArray *channelTypes = [data objectAtPath:@"channel_types" expectedClass:[NSArray class] default:[NSArray array]];
    
    self.channelTypes = [NSMutableArray array];
    for( NSMutableDictionary *channelTypeData in channelTypes )
    {
        ZNGChannelType *channelType = [[ZNGChannelType alloc] init];
        [channelType hydrate:[channelTypeData mutableCopy]];
        [self.channelTypes addObject:channelType];
    }
    
    NSArray *contactCustomFields = [data objectAtPath:@"contact_custom_fields" expectedClass:[NSArray class] default:[NSArray array]];
    
    self.contactCustomFields = [NSMutableArray array];
    for( NSMutableDictionary *customFieldData in contactCustomFields ) {
        ZNGCustomField *customField = [[ZNGCustomField alloc] initWithService:self];
        [customField hydrate:[customFieldData mutableCopy]];
        [self.contactCustomFields addObject:customField];
    }
    
    NSArray *contactLabels = [data objectAtPath:@"contact_labels" expectedClass:[NSArray class] default:[NSArray array]];
    
    self.contactLabels = [NSMutableArray array];
    for( NSMutableDictionary *labelData in contactLabels ) {
        ZNGLabel *label = [[ZNGLabel alloc] initWithService:self];
        [label hydrate:[labelData mutableCopy]];
        [self.contactLabels addObject:label];
    }
}

- (ZNGContact *)newContact
{
    ZNGContact *contact = [[ZNGContact alloc] initWithService:self];
    return contact;
}

- (ZNGContact *)contactWithID:(NSString *)contactID
{
    ZNGContact *contact = [[ZNGContact alloc] initWithService:self];
    contact.ID = contactID;
    return contact;
}

- (BOOL)populateAllContactCustomFieldsWithError:(NSError **)error
{
    ZNGContactCustomFieldSearch *customFieldSearch = [[ZNGContactCustomFieldSearch alloc] initWithService:self];
    customFieldSearch.pageSize = 1000;
    NSArray *contactCustomFields = [customFieldSearch searchWithError:error];
    
    if( contactCustomFields != nil ) {
        self.contactCustomFields = [contactCustomFields mutableCopy];
        return YES;
    }
    
    return NO;
}

- (void)populateAllContactCustomFieldsWithCompletionBlock:( void (^)(void) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock
{
    ZNGContactCustomFieldSearch *customFieldSearch = [[ZNGContactCustomFieldSearch alloc] initWithService:self];
    customFieldSearch.pageSize = 1000;
    
    [customFieldSearch searchWithCompletionBlock:^(NSArray *results) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.contactCustomFields = [results mutableCopy];
            completionBlock();
        });
    } errorBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}

- (ZNGCustomField *)getCustomFieldByDisplayName:(NSString *)displayName
{
    // First loop through all custom fields, and return Globals if they match
    for( ZNGCustomField *customField in self.contactCustomFields ) {
        if( [customField.displayName isEqualToString:displayName] && customField.isGlobal ) {
            return customField;
        }
    }
    
    // Next loop through all custom fields, and return first match
    for( ZNGCustomField *customField in self.contactCustomFields ) {
        if( [customField.displayName isEqualToString:displayName] ) {
            return customField;
        }
    }
    return nil;
}

- (ZNGServiceChannel *)provisionPhoneNumber:(ZNGAvailablePhoneNumber *)availablePhoneNumber asDefaultChannel:(BOOL)isDefault error:(NSError **)error
{
    ZNGServiceChannel *newChannel = [self buildServicePhoneNumberChannelFor:availablePhoneNumber asDefault:isDefault];
    BOOL saved = [newChannel saveWithError:error];
    if( saved ) {
        [self.channels addObject:newChannel];
        return newChannel;
    }
    return nil;
}

- (void)provisionPhoneNumber:(ZNGAvailablePhoneNumber *)availablePhoneNumber asDefaultChannel:(BOOL)isDefault withCompletionBlock:( void (^)(ZNGServiceChannel *newServiceChannel) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock
{
    ZNGServiceChannel *newChannel = [self buildServicePhoneNumberChannelFor:availablePhoneNumber asDefault:isDefault];
    
    [newChannel saveWithCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.channels addObject:newChannel];
            completionBlock(newChannel);
        });
    } errorBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}

- (ZNGServiceChannel *)buildServicePhoneNumberChannelFor:(ZNGAvailablePhoneNumber *)availablePhoneNumber asDefault:(BOOL)isDefault
{
    ZNGServiceChannel *newChannel = [[ZNGServiceChannel alloc] initWithService:self];
    newChannel.channelType = [self firstChannelTypeWithClass:@"PhoneNumber"];
    newChannel.isDefaultForType = isDefault;
    newChannel.value = availablePhoneNumber.phoneNumber;
    newChannel.formattedValue = availablePhoneNumber.formattedPhoneNumber;
    newChannel.country = availablePhoneNumber.country;
    return newChannel;
}

- (NSMutableArray *)channelTypesWithClass:(NSString *)typeClass
{
    NSMutableArray *channelTypes = [NSMutableArray array];
    
    for( ZNGChannelType *channelType in self.channelTypes )
    {
        if( [channelType.typeClass isEqualToString:typeClass] )
        {
            [channelTypes addObject:channelType];
        }
    }
    return channelTypes;
}

- (NSMutableArray *)channelTypesWithClass:(NSString *)typeClass andDisplayName:(NSString *)displayName
{
    NSMutableArray *channelTypes = [self channelTypesWithClass:typeClass];
    
    for( ZNGChannelType *channelType in channelTypes )
    {
        if( ![channelType.displayName isEqualToString:displayName] )
        {
            [channelTypes removeObject:channelType];
        }
    }
    return channelTypes;
}


- (ZNGChannelType *)firstChannelTypeWithClass:(NSString *)typeClass
{
    NSArray *channelTypes = [self channelTypesWithClass:typeClass];
    if( [channelTypes count] > 0 )
    {
        return [channelTypes firstObject];
    }
    return nil;
}

- (ZNGChannelType *)firstChannelTypeWithClass:(NSString *)typeClass andDisplayName:(NSString *)displayName
{	
    NSArray *channelTypes = [self channelTypesWithClass:typeClass andDisplayName:displayName];
    if( [channelTypes count] > 0 )
    {
        return [channelTypes firstObject];
    }
    return nil;
}

- (ZNGChannelType *)channelTypeWithID:(NSString *)channelTypeID
{
    for( ZNGChannelType *channelType in self.channelTypes )
    {
        if( [channelType.ID isEqualToString:channelTypeID] )
        {
            return channelType;
        }
    }
    return nil;
}

- (ZNGServiceChannel *)newChannel
{
    return [[ZNGServiceChannel alloc] initWithService:self];
}

- (ZNGLabel *)newLabel
{
    return [[ZNGLabel alloc] initWithService:self];
}

- (ZNGCustomField *)newCustomField
{
    return [[ZNGCustomField alloc] initWithService:self];
}

- (ZNGMessage *)newMessage
{
    return [[ZNGMessage alloc] initWithService:self];
}

- (NSString *)description
{
    NSString *description = @"<ZNGService> {\r";
    description = [description stringByAppendingFormat:@"    ID: %@\r", self.ID];
    if( self.account != nil )
    {
        description = [description stringByAppendingFormat:@"    Account ID: %@\r", self.account.ID];
    }
    description = [description stringByAppendingFormat:@"    displayName: %@\r", self.displayName];
    description = [description stringByAppendingFormat:@"    plan: %@\r", self.plan];
    description = [description stringByAppendingFormat:@"    timeZone: %@\r", self.timeZone];
    description = [description stringByAppendingFormat:@"    address: %@\r", self.address];
    description = [description stringByAppendingFormat:@"    channels: %@\r", self.channels];
    description = [description stringByAppendingFormat:@"    channelTypes: %@\r", self.channelTypes];
    description = [description stringByAppendingFormat:@"    contactCustomFields: %@\r", self.contactCustomFields];
    description = [description stringByAppendingFormat:@"    contactLabels: %@\r", self.contactLabels];
    description = [description stringByAppendingFormat:@"    created: %@\r", self.created];
    description = [description stringByAppendingFormat:@"    updated: %@\r", self.updated];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}

- (void)preDestroyValidation
{
    // OK
}

- (BOOL)cancelSubscriptionNowWithError:(NSError **)error
{
    return [self destroyWithError:error];
}

- (NSError *)preSaveValidation
{
    if( self.account == nil ) {
        return [[ZingleSDK sharedSDK] genericError:@"Cannot save when Service has no Account set." code:0];
    }
    if( self.plan == nil ) {
        return [[ZingleSDK sharedSDK] genericError:@"Cannot save when Service has no Plan set." code:0];
    }
    if( self.timeZone == nil || [self.timeZone isEqualToString:@""] ) {
        return [[ZingleSDK sharedSDK] genericError:@"Cannot save when Service has no TimeZone set." code:0];
    }
    if( self.address == nil ) {
        return [[ZingleSDK sharedSDK] genericError:@"Cannot save when Service has no Address set." code:0];
    }
    
    return nil;
}

- (NSError *)preRefreshValidation
{
    return nil;
}

- (NSMutableDictionary *)asDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setObject:self.account.ID forKey:@"account_id"];
    [dictionary setObject:self.displayName forKey:@"display_name"];
    [dictionary setObject:self.timeZone forKey:@"time_zone"];
    [dictionary setObject:self.plan.code forKey:@"plan_code"];
    [dictionary setObject:[self.address asDictionary] forKey:@"service_address"];
    
    return dictionary;
}

- (ZNGLabelSearch *)labelSearch
{
    return [[ZNGLabelSearch alloc] initWithService:self];
}

- (ZNGServiceSettingsSearch *)serviceSettingsSearch
{
    return [[ZNGServiceSettingsSearch alloc] initWithService:self];
}

- (ZNGContactSearch *)contactSearch
{
    return [[ZNGContactSearch alloc] initWithService:self];
}

- (ZNGContactCustomFieldSearch *)customFieldSearch
{
    return [[ZNGContactCustomFieldSearch alloc] initWithService:self];
}

- (ZNGMessageSearch *)messageSearch
{
    return [[ZNGMessageSearch alloc] initWithService:self];
}

- (ZNGAutomationSearch *)automationSearch
{
    return [[ZNGAutomationSearch alloc] initWithService:self];
}

- (ZNGWebServiceLogSearch *)webServiceLogSearch
{
    return [[ZNGWebServiceLogSearch alloc] initWithService:self];
}

- (ZNGAvailablePhoneNumberSearch *)availablePhoneNumberSearch
{
    return [[ZNGAvailablePhoneNumberSearch alloc] initWithService:self];
}

@end
