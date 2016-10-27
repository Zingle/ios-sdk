//
//  ZNGMockAccountClient.h
//  ZingleSDK
//
//  Created by Jason Neel on 10/27/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import <ZingleSDK/ZingleSDK.h>
#import "ZingleSDK/ZNGAccountClient.h"

@interface ZNGMockAccountClient : ZNGAccountClient

@property (nonatomic, strong) NSArray<ZNGAccount *> * accounts;

@end
