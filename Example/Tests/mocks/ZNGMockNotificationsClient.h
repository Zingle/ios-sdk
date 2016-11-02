//
//  ZNGMockNotificationsClient.h
//  ZingleSDK
//
//  Created by Jason Neel on 11/2/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import "ZingleSDK/ZNGNotificationsClient.h"

@interface ZNGMockNotificationsClient : ZNGNotificationsClient

/**
 *  Set of all service IDs that have been registered by this notifications client.  Note that device IDs are ignored.
 */
@property (nonatomic, strong, nullable) NSSet<NSString *> * registeredServiceIds;

@end
