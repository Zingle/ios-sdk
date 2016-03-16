//
//  ZNGDataSet.h
//  Pods
//
//  Created by Ryan Farley on 2/18/16.
//
//

#import <Foundation/Foundation.h>
#import "ZNGService.h"
#import "ZNGContact.h"
#import "ZNGConversation.h"

@interface ZNGDataSet : NSObject

/**
 * Returns the data set singleton object.
 */
+ (instancetype)sharedDataSet;

/**
 * Add service object to shared data set.
 */
- (void)addService:(ZNGService *)services;

/**
 * Add service object to shared data set.
 */
- (void)addContact:(ZNGContact *)contact;

/**
 * Add conversation object to a service to shared data set.
 */
- (void)addConversation:(ZNGConversation *)conversation toServiceId:(NSString *)serviceId;

/**
 * Add conversation object to a contact to shared data set.
 */
- (void)addConversation:(ZNGConversation *)conversation toContactId:(NSString *)contactId;

/**
 * Get conversation object to a service from shared data set with id of service.
 */
- (ZNGConversation *)getConversationToServiceId:(NSString *)serviceId;

/**
 * Get conversation object to a contact from shared data set with id of service.
 */
- (ZNGConversation *)getConversationToContactId:(NSString *)contactId;

@end
