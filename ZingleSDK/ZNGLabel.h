//
//  ZNGLabel.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ZingleModel.h"

extern NSString * const ZINGLE_COLOR_DARK_GRAY;
extern NSString * const ZINGLE_COLOR_GRAY;
extern NSString * const ZINGLE_COLOR_LIGHT_GRAY;
extern NSString * const ZINGLE_COLOR_GREEN;
extern NSString * const ZINGLE_COLOR_BROWN;
extern NSString * const ZINGLE_COLOR_RED;
extern NSString * const ZINGLE_COLOR_EXTRA_DARK_BLUE;
extern NSString * const ZINGLE_COLOR_DARK_BLUE;
extern NSString * const ZINGLE_COLOR_BLUE;
extern NSString * const ZINGLE_COLOR_LIGHT_BLUE;
extern NSString * const ZINGLE_COLOR_EXTRA_LIGHT_BLUE;

@class ZNGService;

@interface ZNGLabel : ZingleModel

@property (nonatomic, retain) ZNGService *service;
@property (nonatomic, retain) NSString *displayName;
@property (nonatomic) BOOL isGlobal;
@property (nonatomic, retain) UIColor *backgroundColor, *textColor;

- (id)initWithService:(ZNGService *)service;

@end
