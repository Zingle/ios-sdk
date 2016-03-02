//
//  ZingleSDK.h
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "ZNGConversationViewController.h"
#import "ZNGConversation.h"

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
 * @param serviceId ID of service, which participates in conversation
 * @param contactId ID of contact, which participates in conversation
 * @param contactChannelValue contact channel value for sending messages to service
 */
- (void)addConversationFromContactId:(NSString *)contactId
                         toServiceId:(NSString *)serviceId
                 contactChannelValue:(NSString *)contactChannelValue
                             success:(void (^)(ZNGConversation* conversation))success
                             failure:(void (^)(ZNGError* error))failure;

/**
 * Registers a new conversation in ZingleSDK. This will return a chat interface from a service to a contact. On success,
 * system will receive all messages for specified service and contact IDs. It will then be possible to create the UI for
 * this conversation with conversationViewControllerForService:serviceId. Can be called as many times as needed to add all
 * conversations.
 *
 * @param serviceId ID of service, which participates in conversation
 * @param contactId ID of contact, which participates in conversation
 * @param contactChannelValue contact channel value for sending messages to service
 */
- (void)addConversationFromServiceId:(NSString *)serviceId
                         toContactId:(NSString *)contactId
                 contactChannelValue:(NSString *)contactChannelValue
                             success:(void (^)(ZNGConversation* conversation))success
                             failure:(void (^)(ZNGError* error))failure;

/**
 * Returns a new conversation view controller for the specified conversation that can be presented and/or added to a navigation stack.
 *
 * @param conversation object which contains the messages to display
 */
- (ZNGConversationViewController *)conversationViewControllerForConversation:(ZNGConversation *)conversation;

@end
