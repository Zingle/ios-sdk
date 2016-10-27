//
//  ZNGMockContactServiceClient.h
//  ZingleSDK
//
//  Created by Jason Neel on 10/26/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import <ZingleSDK/ZingleSDK.h>
#import "ZingleSDK/ZNGContactServiceClient.h"

@interface ZNGMockContactServiceClient : ZNGContactServiceClient

/**
 *  The contact services to be returned through network requests
 */
@property (nonatomic, strong) NSArray<ZNGContactService *> * contactServices;

@end
