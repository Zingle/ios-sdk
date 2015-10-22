//
//  ZNGCustomFieldValue.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleModel.h"

@class ZNGCustomField;
@class ZNGCustomFieldOption;
@class ZNGService;
@class ZNGContact;

@interface ZNGCustomFieldValue : ZingleModel

@property (nonatomic, retain) ZNGContact *contact;
@property (nonatomic, retain) ZNGService *service;
@property (nonatomic, retain) ZNGCustomField *customField;
@property (nonatomic, retain) NSString *value, *selectedCustomFieldOptionId;

- (id)initWithContact:(ZNGContact *)contact;
- (id)initWithService:(ZNGService *)service;
- (ZNGCustomFieldOption *)selectedCustomFieldOption;

@end
