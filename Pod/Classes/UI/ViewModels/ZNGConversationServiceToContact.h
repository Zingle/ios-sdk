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

/**
 *  The receiving channel.  This value can be changed after initialization.  Outgoing messages will leave on the default channel for this
 *   channel type.
 *
 *  This value will only be null in the probably nonsense case of a contact with no default channel and no phone number channel.
 */
@property (nonatomic, strong, nullable) ZNGChannel * channel;

- (id) initFromService:(ZNGService*)aService toContact:(ZNGContact *)aContact withMessageClient:(ZNGMessageClient *)messageClient;
- (id) initFromService:(ZNGService*)aService toContact:(ZNGContact *)aContact usingChannel:(ZNGChannel * __nullable)aChannel withMessageClient:(ZNGMessageClient *)messageClient NS_DESIGNATED_INITIALIZER;

NS_ASSUME_NONNULL_END

@end
