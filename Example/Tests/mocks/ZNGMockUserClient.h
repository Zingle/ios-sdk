//
//  ZNGMockUserClient.h
//  ZingleSDK
//
//  Created by Jason Neel on 4/10/17.
//  Copyright © 2017 Zingle. All rights reserved.
//

#import "ZingleSDK/ZNGUserClient.h"

@class ZNGContact;

@interface ZNGMockUserClient : ZNGUserClient

@property (nonatomic, strong) ZNGUser * user;

@end
