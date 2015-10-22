//
//  ZNGAddress.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleModel.h"

@interface ZNGAddress : ZingleModel

@property (nonatomic, retain) NSString *address, *city, *country, *postalCode, *state;

@end
