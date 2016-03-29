//
//  ZingleSDK.h
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import <Foundation/Foundation.h>
#import "ZNGConversationViewController.h"
#import "ZNGConversation.h"
#import "ZNGContact.h"
#import "ZNGService.h"

@interface ZingleSDK : NSObject

/**
 * Returns the ZingleSDK singleton object.
 */
+ (instancetype)sharedSDK;

/**
 * Initializes basic auth for connecting to API. Does not verify login and password are correct.
 *
 * @param token user name for API
 * @param password password for API
 */
- (void)setToken:(NSString*)token andKey:(NSString*)key;

/**
 * Registers a new conversation in ZingleSDK. This will return a chat interface from a contact to a service. On success,
 * system will receive all messages for specified contact and service IDs. It will then be possible to create the UI for
 * this conversation with conversationViewControllerForService:serviceId. Can be called as many times as needed to add all 
 * conversations.
 *
 * @param service which participates in conversation
 * @param contact which participates in conversation
 */
- (void)addConversationFromContact:(ZNGContact *)contact
                         toService:(ZNGService *)service
                           success:(void (^)(ZNGConversation* conversation))success
                           failure:(void (^)(ZNGError* error))failure;

/**
 * Registers a new conversation in ZingleSDK. This will return a chat interface from a service to a contact. On success,
 * system will receive all messages for specified service and contact IDs. It will then be possible to create the UI for
 * this conversation with conversationViewControllerForService:serviceId. Can be called as many times as needed to add all
 * conversations.
 *
 * @param service which participates in conversation
 * @param contact which participates in conversation
 */
- (void)addConversationFromService:(ZNGService *)service
                         toContact:(ZNGContact *)contact
                           success:(void (^)(ZNGConversation* conversation))success
                           failure:(void (^)(ZNGError* error))failure;

/**
 *  Returns a ZNGConversation conversation Object containing participants in a conversation and the
 *  conversation messages
 *
 *  @param serviceId service that the conversation is sent to
 */
- (ZNGConversation *)conversationToService:(NSString *)serviceId;

/**
 *  Returns a ZNGConversation conversation Object containing participants in a conversation and the
 *  conversation messages
 *
 *  @param contactId contact that the conversation is sent to
 */
- (ZNGConversation *)conversationToContact:(NSString *)contactId;

/**
 *  Returns a ZNGConversationViewController.
 *
 *  @param conversation Object containing participants in a conversation and the
 *  conversation messages. Controller must be created with conversation.
 */
- (ZNGConversationViewController *)conversationViewControllerToService:(ZNGService *)service
                                                               contact:(ZNGContact *)contact
                                                            senderName:(NSString *)senderName
                                                          receiverName:(NSString *)receiverName;

/**
 *  Returns a ZNGConversationViewController.
 *
 *  @param conversation Object containing participants in a conversation and the
 *  conversation messages. Controller must be created with conversation.
 */
- (ZNGConversationViewController *)conversationViewControllerToContact:(ZNGContact *)contact
                                                               service:(ZNGService *)service
                                                            senderName:(NSString *)senderName
                                                          receiverName:(NSString *)receiverName;

- (void)setToken:(NSString *)token andKey:(NSString *)key forDebugMode:(BOOL)debugMode;
@end
