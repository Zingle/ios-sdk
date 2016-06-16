//
//  ZingleContactSession.h
//  Pods
//
//  Created by Jason Neel on 6/15/16.
//
//
#import "ZingleSession.h"
#import "ZingleSDK.h"

NS_ASSUME_NONNULL_BEGIN

@class ZNGContactService;
@class ZNGConversation;
@class ZNGError;

@class ZNGAutomationClient;
@class ZNGContact;
@class ZNGContactClient;
@class ZNGMessageClient;
@class ZNGTemplateClient;

@class ZNGConversationViewController;

@interface ZingleContactSession : ZingleSession

/**
 *  Channel type ID as specified during initialization.  e.g. "1234-123456-1234," the ID representing "My Hotels Messaging."
 */
@property (nonatomic, readonly, nonnull) NSString * channelTypeID;

/**
 *  Channel value as specified during initializaion.  e.g. "johnsmith123," the username for the user in My Hotels Messaging.
 */
@property (nonatomic, readonly, nonnull) NSString * channelValue;

/**
 *  The KVO-observable array of available Contact Services, containing ZNGContactService objects representing services such
 *   as "Chicago Special Hotel Spa," "Miami Schmyatt Hotel Valet," "San Francisco Hotel Front Desk"
 */
@property (nonatomic, readonly, nullable) NSArray<ZNGContactService *> * availableContactServices;

/**
 *  An optional callback to be called whenever new values for availableContactServices arrive.  This block is retained even after being called, so weak references
 *   should be used when possible.
 */
@property (nonatomic, copy, nullable) ZNGContactServiceChooser contactServiceChooser;

/**
 *  The getter and setter for the current contactService selection.  When setting, the value must be present in availableContactServices.
 *
 *  Setting this value resets the contact and conversation properties to nil until they can be retrieved from the server a few moments later.
 */
@property (nonatomic, strong, nullable) ZNGContactService * contactService;

/**
 *  The current user's contact object under the current contact service.  Set automatically shortly after a contact service is selected.
 */
@property (nonatomic, readonly, nullable) ZNGContact * contact;

/**
 *  The current messaging conversation between the contact and the contact service.  Al messages are sent and received through this property.
 *  This is set automatically along with the contact property.
 */
@property (nonatomic, readonly, nullable) ZNGConversation * conversation;

#pragma mark - Clients used internally for connectivity
@property (nonatomic, strong, nullable) ZNGAutomationClient * automationClient;
@property (nonatomic, strong, nullable) ZNGContactClient * contactClient;
@property (nonatomic, strong, nullable) ZNGMessageClient * messageClient;
@property (nonatomic, strong, nullable) ZNGTemplateClient * templateClient;

/**
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

/**
 *  Constructs and returns a view controller for the current conversation.
 */
- (ZNGConversationViewController *) conversationViewController;

@end

NS_ASSUME_NONNULL_END