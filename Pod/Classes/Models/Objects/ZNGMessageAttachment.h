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

@property (nonatomic, retain) NSString *url;

- (void)setImage:(UIImage *)image;
- (void)setData:(NSData *)data withContentType:(NSString *)contentType;

- (UIImage *)getImageWithError:(NSError **)error;
- (void)getImageWithCompletionBlock:(void (^) (UIImage *image))completionBlock
                         errorBlock:(void (^) (NSError *requestError))errorBlock;

@end