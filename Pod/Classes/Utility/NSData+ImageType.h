//
//  NSData+ImageType.h
//  Pods
//
//  Created by Jason Neel on 4/11/17.
//
//

#import <Foundation/Foundation.h>

extern NSString * _Nonnull const NSDataImageContentTypeGif;
extern NSString * _Nonnull const NSDataImageContentTypeJpeg;
extern NSString * _Nonnull const NSDataImageContentTypePng;
extern NSString * _Nonnull const NSDataImageContentTypeTiff;

@interface NSData (ImageType)

/**
 *  For image data, returns a string content type of the form "image/jpeg"
 *  For non-image data, behavior is undefined.
 */
- (NSString * _Nullable) imageContentType;

@end
