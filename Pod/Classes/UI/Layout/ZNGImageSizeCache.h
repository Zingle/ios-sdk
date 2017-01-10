//
//  ZNGImageSizeCache.h
//  Pods
//
//  Created by Jason Neel on 1/6/17.
//
//

#import <Foundation/Foundation.h>

@interface ZNGImageSizeCache : NSObject

+ (instancetype) sharedCache;

- (CGSize) sizeForImageWithPath:(NSString *)filename;
- (void) setSize:(CGSize)size forImageWithPath:(NSString *)filename;

@end
