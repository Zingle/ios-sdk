//
//  ZNGCustomFieldOption.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleModel.h"

@interface ZNGCustomFieldOption : ZingleModel

@property (nonatomic, retain) NSString *displayName, *value;
@property (nonatomic, retain) NSNumber *sortOrder;

@end
