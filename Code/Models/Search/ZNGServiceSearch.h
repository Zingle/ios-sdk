//
//  ZNGServiceSearch.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleModelSearch.h"

@interface ZNGServiceSearch : ZingleModelSearch

@property (nonatomic, retain) NSString *phoneNumberPattern;
@property (nonatomic, retain) NSString *planId;
@property (nonatomic, retain) NSString *serviceDisplayName;
@property (nonatomic, retain) NSString *serviceAddress;
@property (nonatomic, retain) NSString *serviceCity;
@property (nonatomic, retain) NSString *serviceState;
@property (nonatomic, retain) NSString *servicePostalCode;
@property (nonatomic, retain) NSString *serviceCountry;

@end
