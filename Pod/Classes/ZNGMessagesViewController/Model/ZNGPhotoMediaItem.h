//
//  ZNGPhotoMediaItem.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//
#import "ZNGMediaItem.h"

/**
 *  The `ZNGPhotoMediaItem` class is a concrete `ZNGMediaItem` subclass that implements the `ZNGMessageMediaData` protocol
 *  and represents a photo media message. An initialized `ZNGPhotoMediaItem` object can be passed 
 *  to a `ZNGMediaMessage` object during its initialization to construct a valid media message object.
 *  You may wish to subclass `ZNGPhotoMediaItem` to provide additional functionality or behavior.
 */
@interface ZNGPhotoMediaItem : ZNGMediaItem <ZNGMessageMediaData, NSCoding, NSCopying>

/**
 *  The image for the photo media item. The default value is `nil`.
 */
@property (copy, nonatomic) UIImage *image;

/**
 *  Initializes and returns a photo media item object having the given image.
 *
 *  @param image The image for the photo media item. This value may be `nil`.
 *
 *  @return An initialized `ZNGPhotoMediaItem` if successful, `nil` otherwise.
 *
 *  @discussion If the image must be dowloaded from the network, 
 *  you may initialize a `ZNGPhotoMediaItem` object with a `nil` image. 
 *  Once the image has been retrieved, you can then set the image property.
 */
- (instancetype)initWithImage:(UIImage *)image;

@end
