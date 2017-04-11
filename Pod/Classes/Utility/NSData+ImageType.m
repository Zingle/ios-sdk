//
//  NSData+ImageType.m
//  Pods
//
//  Created by Jason Neel on 4/11/17.
//
//

#import "NSData+ImageType.h"

NSString * const NSDataImageContentTypeGif = @"image/gif";
NSString * const NSDataImageContentTypeJpeg = @"image/jpeg";
NSString * const NSDataImageContentTypePng = @"image/png";
NSString * const NSDataImageContentTypeTiff = @"image/tiff";

@implementation NSData (ImageType)

- (NSString * _Nullable) imageContentType;
{
    uint8_t firstChar;
    [self getBytes:&firstChar length:1];
    
    switch (firstChar) {
        case 0xFF:
            return NSDataImageContentTypeJpeg;
        case 0x89:
            return NSDataImageContentTypePng;
        case 0x47:
            return NSDataImageContentTypeGif;
        case 0x49:
        case 0x4D:
            return NSDataImageContentTypeTiff;
        default:
            return nil;
    }
}

@end
