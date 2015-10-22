//
//  ZNGAvailablePhoneNumberSearch.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleModelSearch.h"

@class ZNGService;

@interface ZNGAvailablePhoneNumberSearch : ZingleModelSearch

@property (nonatomic, retain) NSString *country, *areaCode, *searchPattern;

@end
