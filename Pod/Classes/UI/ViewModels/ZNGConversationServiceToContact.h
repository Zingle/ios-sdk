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
@property (nonatomic, readonly) ZNGContact * contact;
@property (nonatomic, readonly) ZNGService * service;
@property (nonatomic, readonly) NSString * myUserId;

@property (nonnull, strong) ZNGContactClient * contactClient;

/**
 *  The receiving channel.  This value can be changed after initialization.  Outgoing messages will leave on the default channel for this
 *   channel type.
 *
 *  This value will only be null in the probably nonsense case of a contact with no default channel and no phone number channel.
 */
@property (nonatomic, strong, nullable) ZNGChannel * channel;

- (id) initFromService:(ZNGService*)aService
             toContact:(ZNGContact *)aContact
     withCurrentUserId:(NSString *)userId
          usingChannel:(ZNGChannel * __nullable)aChannel
     withMessageClient:(ZNGMessageClient *)messageClient
           eventClient:(ZNGEventClient *)eventClient
         contactClient:(ZNGContactClient *)contactClient NS_DESIGNATED_INITIALIZER;

- (id) initWithMessageClient:(ZNGMessageClient *)messageClient eventClient:(ZNGEventClient *)eventClient NS_UNAVAILABLE;

/**
 *  If the contact has a default channel set, this will return that value.
 *  If no default is set, this will attempt to find the most recently used channel or, failing that, a default or sole phone number.
 *
 *  If conversation data has not yet been loaded, this will return the default using contact information.  (If at all possible, this
 *   should not be called until conversation data has loaded.)
 */
- (ZNGChannel *) defaultChannelForContact;

- (void) addInternalNote:(NSString *)note
                 success:(nullable void (^)(ZNGStatus* status))success
                 failure:(nullable void (^) (ZNGError *error))failure;

- (void) triggerAutomation:(ZNGAutomation *)automation completion:(void (^)(BOOL success))completion;

NS_ASSUME_NONNULL_END

@end
