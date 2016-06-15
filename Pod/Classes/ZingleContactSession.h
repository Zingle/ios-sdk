//
//  ZingleContactSession.h
//  Pods
//
//  Created by Jason Neel on 6/15/16.
//
//
#import "ZingleSession.h"

NS_ASSUME_NONNULL_BEGIN

@class ZNGContactService;
@class ZNGError;

@class ZNGAutomationClient;
@class ZNGContact;
@class ZNGContactClient;
@class ZNGMessageClient;
@class ZNGTemplateClient;

typedef ZNGContactService * _Nullable (^ZNGContactServiceChooser)(NSArray<ZNGContactService *> *);

@interface ZingleContactSession : ZingleSession

@property (nonatomic, readonly, nonnull) NSString * channelTypeID;
@property (nonatomic, readonly, nonnull) NSString * channelValue;

@property (nonatomic, readonly, nullable) NSArray<ZNGContactService *> * availableContactServices;
@property (nonatomic, copy, nullable) ZNGContactServiceChooser contactServiceChooser;

@property (nonatomic, strong, nullable) ZNGContactService * contactService;

/*
 *  Set automatically shortly after a contact service is selected.
 */
@property (nonatomic, readonly, nullable) ZNGContact * contact;

@property (nonatomic, strong, nullable) ZNGAutomationClient * automationClient;
@property (nonatomic, strong, nullable) ZNGContactClient * contactClient;
@property (nonatomic, strong, nullable) ZNGMessageClient * messageClient;
@property (nonatomic, strong, nullable) ZNGTemplateClient * templateClient;

/*
 *  The initializer for a Zingle session in the Contact domain.  This includes both authentication information for the API user (i.e. the develoepr) and a set of identifying
 *   information for the contact to be sending messages, etc.
 *
 *  Once a list of available, matching contact services has been returned by the server, the availableContactServices array will be populated and the contactServiceChooser will
 *   be called if one was provided.
 *
 *  @param token Token for Zingle API user
 *  @param key Security key for Zingle API user
 *  @param channelTypeId An identifier for the channel type, e.g. the identifier for Big Hotel Messaging System
 *  @param channelValue The channel value for the current user, e.g. joeSchmoe97 for the user name in Big Hotel Messaging System
 *  @param contactServiceChooser Optional block to be used to select a contact service once we obtain the list of available contact services.  May be neglected or return nil.
 *   This block is retained indefinitely, so weak references should be used or the contactServiceChooser property should be set to nil if no longer needed.
 */
- (instancetype) initWithToken:(NSString *)token key:(NSString *)key channelTypeId:(NSString *)channelTypeId channelValue:(NSString *)channelValue contactServiceChooser:(ZNGContactServiceChooser)contactServiceChooser;

@end

NS_ASSUME_NONNULL_END