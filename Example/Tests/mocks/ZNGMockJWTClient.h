//
//  ZNGMockJWTClient.h
//  Tests
//
//  Created by Jason Neel on 7/17/19.
//  Copyright © 2019 Zingle. All rights reserved.
//

#import "ZingleSDK/ZNGJWTClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZNGMockJWTClient : ZNGJWTClient

- (id) init;  // Allow parameterless init for mocking

@end

NS_ASSUME_NONNULL_END
