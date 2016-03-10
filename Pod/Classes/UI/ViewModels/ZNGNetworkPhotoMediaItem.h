//
//  ZNGNetworkPhotoMediaItem.h
//  Pods
//
//  Created by Ryan Farley on 3/9/16.
//
//

#import "ZNGPhotoMediaItem.h"

/**
 *  The `ZNGNetworkPhotoMediaItem` class is a concrete `ZNGPhotoMediaItem` subclass that implements the
 *  `ZNGMessageMediaData` protocol and represents a photo media message that needs to be downloaded. An initialized
 *  `ZNGNetworkPhotoMediaItem` object can be passed to a `ZNGMediaMessage` object during its initialization
 *  to construct a valid media message object. You may wish to subclass `ZNGNetworkPhotoMediaItem` to provide 
 *  additional functionality or behavior.
 */
@interface ZNGNetworkPhotoMediaItem : ZNGPhotoMediaItem

/**
 *  The URL string for the photo to be downloaded. The default value is `nil`.
 */
@property (copy, nonatomic) NSString *url;

/**
 *  Initializes and returns a network photo media item object having the given URL.
 *
 *  @param url The URL for the photo to download. This value may be `nil`.
 *
 *  @return An initialized `ZNGNetworkPhotoMediaItem` if successful, `nil` otherwise.
 *
 *  @discussion If the image must be dowloaded from the network,
 *  initialize a `ZNGNetworkPhotoMediaItem` object with a URL.
 *  Once the image has been retrieved, the image property will be set.
 */
- (instancetype)initWithURL:(NSString *)url;

@end
