//
//  ZNGMessageAttachment.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZingleModel.h"

extern NSString * const ZINGLE_CONTENT_TYPE_IMAGE_PNG;

@interface ZNGMessageAttachment : ZingleModel

- (void)setImage:(UIImage *)image;
- (void)setData:(NSData *)data withContentType:(NSString *)contentType;

@end