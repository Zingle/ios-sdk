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
 * Add conversation object to shared data set.
 */
- (void)addConversation:(ZNGConversation *)conversation;

/**
 * Get conversation object from shared data set with id of service.
 */
- (ZNGConversation *)getConversationWithServiceId:(NSString *)serviceId;

@end
