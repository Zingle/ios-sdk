//
//  ZNGMockServiceClient.h
//  ZingleSDK
//
//  Created by Jason Neel on 10/27/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import <ZingleSDK/ZingleSDK.h>
#import "ZingleSDK/ZNGServiceClient.h"

@interface ZNGMockServiceClient : ZNGServiceClient

@property (nonatomic, strong) NSArray<ZNGService *> * services;

@end
