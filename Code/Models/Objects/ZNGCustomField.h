//
//  ZNGCustomField.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZingleModel.h"

@class ZNGCustomFieldOption;
@class ZNGService;

@interface ZNGCustomField : ZingleModel

@property (nonatomic, retain) ZNGService *service;
@property (nonatomic, retain) NSString *displayName;
@property (nonatomic) BOOL isGlobal;
@property (nonatomic, retain) NSMutableArray *options;

- (id)initWithService:(ZNGService *)service;
- (ZNGCustomFieldOption *)customFieldOptionWithID:(NSString *)customFieldOptionID;
- (BOOL)deleteFromServiceWithError:(NSError **)error;

@end
