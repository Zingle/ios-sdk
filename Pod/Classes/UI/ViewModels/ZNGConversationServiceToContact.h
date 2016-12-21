//
//  ZNGConversationServiceToContact.h
//  Pods
//
//  Created by Jason Neel on 6/21/16.
//
//

#import <ZingleSDK/ZingleSDK.h>

@interface ZNGConversationServiceToContact : ZNGConversation

NS_ASSUME_NONNULL_BEGIN

/**
 *  The receiving contact.  This is set on initialization and cannot be changed.
 */
@property (nonatomic, strong) ZNGContact * contact;
@property (nonatomic, strong) ZNGService * service;
@property (nonatomic, readonly) NSString * myUserId;

@property (nonnull, strong) ZNGContactClient * contactClient;

/**
 *  The receiving channel.  This value can be changed after initialization.  Outgoing messages will leave on the default channel for this
 *   channel type.
 *
 *  This value will only be null in the probably nonsense case of a contact with no default channel and no phone number channel.
 */
@property (nonatomic, strong, nullable) ZNGChannel * channel;

/**
 *  Convenience getter to retrieve the current session from our client.
 */
@property (nonatomic, readonly) ZingleAccountSession * session;

- (id) initFromService:(ZNGService*)aService
             toContact:(ZNGContact *)aContact
     withCurrentUserId:(NSString *)userId
          usingChannel:(ZNGChannel * __nullable)aChannel
     withMessageClient:(ZNGMessageClient *)messageClient
           eventClient:(ZNGEventClient *)eventClient
         contactClient:(ZNGContactClient *)contactClient
          socketClient:(ZNGSocketClient *)socketClient NS_DESIGNATED_INITIALIZER;

- (id) initWithMessageClient:(ZNGMessageClient *)messageClient eventClient:(ZNGEventClient *)eventClient NS_UNAVAILABLE;

/**
 *  If the contact has a default channel set, this will return that value.
 *  If no default is set, this will attempt to find the most recently used channel or, failing that, a default or sole phone number.
 *
 *  If conversation data has not yet been loaded, this will return the default using contact information.  (If at all possible, this
 *   should not be called until conversation data has loaded.)
 */
- (ZNGChannel *) defaultChannelForContact;

/**
 *  Tell the server that the user is typing a response
 */
- (void) userDidType:(nullable NSString *)pendingInput;

/**
 *  Tell the server that the user cleared the input field.  This is called automatically whenever a message is sent.
 */
- (void) userClearedInput;

- (void) addInternalNote:(NSString *)note
                 success:(void (^ _Nullable)(ZNGStatus* status))success
                 failure:(void (^ _Nullable) (ZNGError *error))failure;

- (void) triggerAutomation:(ZNGAutomation *)automation completion:(void (^)(BOOL success))completion;

- (void) forwardMessage:(ZNGMessage *)message toSMS:(NSString *)phoneNumberString success:(void (^ _Nullable)(ZNGStatus* status))success failure:(void (^ _Nullable) (ZNGError *error))failure;
- (void) forwardMessage:(ZNGMessage *)message toEmail:(NSString *)email success:(void (^ _Nullable)(ZNGStatus* status))success failure:(void (^ _Nullable) (ZNGError *error))failure;
- (void) forwardMessage:(ZNGMessage *)message toHotsosWithHotsosIssueName:(NSString *)hotsosIssueName success:(void (^ _Nullable)(ZNGStatus* status))success failure:(void (^ _Nullable) (ZNGError *error))failure;
- (void) forwardMessage:(ZNGMessage *)message toService:(ZNGService *)service success:(void (^ _Nullable)(ZNGStatus* status))success failure:(void (^ _Nullable) (ZNGError *error))failure;
- (void) forwardMessage:(ZNGMessage *)message toPrinter:(ZNGPrinter *)printer success:(void (^ _Nullable)(ZNGStatus* status))success failure:(void (^ _Nullable) (ZNGError *error))failure;

/**
 *  Returns all remote channels that have been used by this contact in our current data.  Note that, if the contact has used a channel in messages
 *   older than our current data, that channel will *not* be included in this array.
 */
- (NSArray<ZNGChannel *> *) usedChannels;

NS_ASSUME_NONNULL_END

@end
