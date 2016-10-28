//
//  ZNGMockUserAuthorizationClient.h
//  ZingleSDK
//
//  Created by Jason Neel on 10/27/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import "ZingleSDK/ZNGUserAuthorizationClient.h"

@class ZNGContact;

@interface ZNGMockUserAuthorizationClient : ZNGUserAuthorizationClient

/**
 *  The authorization class.  Defaults to "contact"
 */
@property (nonatomic, strong) NSString * authorizationClass;
@property (nonatomic, strong) ZNGContact * contact;

@end
