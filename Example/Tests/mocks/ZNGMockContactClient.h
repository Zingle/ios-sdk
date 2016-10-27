//
//  ZNGMockContactClient.h
//  ZingleSDK
//
//  Created by Jason Neel on 10/19/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import <ZingleSDK/ZingleSDK.h>
#import "ZingleSDK/ZNGContactClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZNGMockContactClient : ZNGContactClient

/**
 *  The contacts used to mock all network requests.
 */
@property (nonatomic, strong, nullable) NSArray<ZNGContact *> * contacts;

- (id) init;

NS_ASSUME_NONNULL_END

@end
