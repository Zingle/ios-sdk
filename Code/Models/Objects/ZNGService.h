//
//  ZNGService.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZingleModel.h"

@class ZNGPlan;
@class ZNGAccount;
@class ZNGAddress;
@class ZNGContact;
@class ZNGServiceChannel;
@class ZNGLabelSearch;
@class ZNGContactSearch;
@class ZNGContactCustomFieldSearch;
@class ZNGMessageSearch;
@class ZNGAutomationSearch;
@class ZNGWebServiceLogSearch;
@class ZNGAvailablePhoneNumberSearch;
@class ZNGServiceSettingsSearch;
@class ZNGChannelType;
@class ZNGLabel;
@class ZNGCustomField;
@class ZNGAvailablePhoneNumber;
@class ZNGMessage;

@interface ZNGService : ZingleModel

@property (nonatomic, retain) ZNGAccount *account;
@property (nonatomic, retain) NSString *displayName, *timeZone;
@property (nonatomic, retain) ZNGPlan *plan;
@property (nonatomic, retain) ZNGAddress *address;
@property (nonatomic, retain) NSMutableArray *channels, *channelTypes, *contactCustomFields, *contactLabels;

- (id)initWithAccount:(ZNGAccount *)account;
- (BOOL)cancelSubscriptionNowWithError:(NSError **)error;
- (ZNGContact *)newContact;
- (ZNGContact *)contactWithID:(NSString *)contactID;

- (BOOL)populateAllContactCustomFieldsWithError:(NSError **)error;
- (void)populateAllContactCustomFieldsWithCompletionBlock:( void (^)(void) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock;
- (ZNGCustomField *)getCustomFieldByDisplayName:(NSString *)displayName;

- (ZNGServiceChannel *)provisionPhoneNumber:(ZNGAvailablePhoneNumber *)availablePhoneNumber asDefaultChannel:(BOOL)asDefault error:(NSError **)error;
- (void)provisionPhoneNumber:(ZNGAvailablePhoneNumber *)availablePhoneNumber asDefaultChannel:(BOOL)isDefault withCompletionBlock:( void (^)(ZNGServiceChannel *newServiceChannel) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock;

- (NSMutableArray *)channelTypesWithClass:(NSString *)typeClass;
- (NSMutableArray *)channelTypesWithClass:(NSString *)typeClass andDisplayName:(NSString *)displayName;

- (ZNGChannelType *)firstChannelTypeWithClass:(NSString *)typeClass;
- (ZNGChannelType *)firstChannelTypeWithClass:(NSString *)typeClass andDisplayName:(NSString *)displayName;
- (ZNGChannelType *)channelTypeWithID:(NSString *)channelTypeID;

- (ZNGLabel *)newLabel;
- (ZNGCustomField *)newCustomField;
- (ZNGMessage *)newMessage;

- (ZNGServiceSettingsSearch *)serviceSettingsSearch;
- (ZNGContactSearch *)contactSearch;
- (ZNGServiceChannel *)newChannel;
- (ZNGLabelSearch *)labelSearch;
- (ZNGContactCustomFieldSearch *)customFieldSearch;
- (ZNGMessageSearch *)messageSearch;
- (ZNGAutomationSearch *)automationSearch;
- (ZNGWebServiceLogSearch *)webServiceLogSearch;
- (ZNGAvailablePhoneNumberSearch *)availablePhoneNumberSearch;

- (ZNGContact *)findOrCreateContactWithChannelTypeID:(NSString *)channelTypeID
                                     andChannelValue:(NSString *)channelValue
                                               error:(NSError **)error;

- (void)findOrCreateContactWithChannelTypeID:(NSString *)channelTypeID
                             andChannelValue:(NSString *)channelValue
                             completionBlock:(void (^) (ZNGContact *contact))completionBlock
                                  errorBlock:(void (^) (NSError *error))errorBlock;

- (ZNGContact *)createContactWithChannelTypeID:(NSString *)channelTypeID
                               andChannelValue:(NSString *)channelValue
                                         error:(NSError **)error;

- (void)createContactWithChannelTypeID:(NSString *)channelTypeID
                            andChannelValue:(NSString *)channelValue
                            completionBlock:(void (^) (ZNGContact *contact))completionBlock
                                errorBlock:(void (^) (NSError *error))errorBlock;

@end
