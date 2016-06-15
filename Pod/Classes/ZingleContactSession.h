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

@interface ZingleContactSession : ZingleSession

@property (nonatomic, readonly, nonnull) NSString * channelTypeID;
@property (nonatomic, readonly, nonnull) NSString * channelValue;

@property (nonatomic, readonly, nullable) ZNGContactService * contactService;
@property (nonatomic, readonly, nullable) ZNGContact * contact;

@property (nonatomic, strong, nullable) ZNGAutomationClient * automationClient;
@property (nonatomic, strong, nullable) ZNGContactClient * contactClient;
@property (nonatomic, strong, nullable) ZNGMessageClient * messageClient;
@property (nonatomic, strong, nullable) ZNGTemplateClient * templateClient;

/*
 *  The initializer for a Zingle session in the Contact domain.  This includes both authentication information for the API user (i.e. the develoepr) and a set of identifying
 *   information for the contact to be sending messages, etc.
 *
 *  @param token Token for Zingle API user
 *  @param key Security key for Zingle API user
 *  @param channelTypeId An identifier for the channel type, e.g. the identifier for Big Hotel Messaging System
 *  @param channelValue The channel value for the current user, e.g. joeSchmoe97 for the user name in Big Hotel Messaging System
 *  @param completion Optional completion block called to indicate success or failure in authenticating the Zingle API user and the provided contact with channelTypeID and channelValue
 */
- (instancetype) initWithToken:(NSString *)token key:(NSString *)key channelTypeId:(NSString *)channelTypeId channelValue:(NSString *)channelValue completion:(nullable void (^)(BOOL success, ZNGError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END