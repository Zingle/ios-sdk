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
 * @param contactChannelValue contact channel value for sending messages to service
 */
- (void)addConversationFromContact:(ZNGContact *)contact
                         toService:(ZNGService *)service
               contactChannelValue:(NSString *)contactChannelValue
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
 * @param contactChannelValue contact channel value for sending messages to service
 */
- (void)addConversationFromService:(ZNGService *)service
                         toContact:(ZNGContact *)contact
               contactChannelValue:(NSString *)contactChannelValue
                           success:(void (^)(ZNGConversation* conversation))success
                           failure:(void (^)(ZNGError* error))failure;


- (ZNGConversation *)conversationToService:(NSString *)serviceId;
- (ZNGConversation *)conversationToContact:(NSString *)contactId;

/**
 * Returns a new conversation view controller for the specified conversation that can be presented and/or added to a navigation stack.
 *
 * @param conversation object which contains the messages to display
 */
- (ZNGConversationViewController *)conversationViewControllerWithService:(ZNGService *)service
                                                                 contact:(ZNGContact *)contact
                                                     contactChannelValue:(NSString *)contactChannelValue
                                                              senderName:(NSString *)senderName
                                                            receiverName:(NSString *)receiverName;

@end
