//
//  ZNGLocationMediaItem.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

/**
 *  A completion handler block for a `ZNGLocationMediaItem`. See `setLocation: withCompletionHandler:`.
 */
typedef void (^ZNGLocationMediaItemCompletionBlock)(void);


#import "ZNGMediaItem.h"

/**
 *  The `ZNGLocationMediaItem` class is a concrete `ZNGMediaItem` subclass that implements the `ZNGMessageMediaData` protocol
 *  and represents a location media message. An initialized `ZNGLocationMediaItem` object can be passed
 *  to a `ZNGMediaMessage` object during its initialization to construct a valid media message object.
 *  You may wish to subclass `ZNGLocationMediaItem` to provide additional functionality or behavior.
 */
@interface ZNGLocationMediaItem : ZNGMediaItem <ZNGMessageMediaData, MKAnnotation, NSCoding, NSCopying>

/**
 *  The location for the media item. The default value is `nil`.
 */
@property (copy, nonatomic) CLLocation *location;

/**
 *  The coordinate of the location property.
 */
@property (readonly, nonatomic) CLLocationCoordinate2D coordinate;

/**
 *  Initializes and returns a location media item object having the given location.
 *
 *  @param location The location for the media item. This value may be `nil`.
 *
 *  @return An initialized `ZNGLocationMediaItem` if successful, `nil` otherwise.
 *
 *  @discussion If the location data must be dowloaded from the network,
 *  you may initialize a `ZNGLocationMediaItem` object with a `nil` location.
 *  Once the location data has been retrieved, you can then set the location property
 *  using `setLocation: withCompletionHandler:`
 */
- (instancetype)initWithLocation:(CLLocation *)location;

/**
 *  Sets the specified location for the location media item and immediately begins creating
 *  a map view snapshot image on a background thread. The map view zooms to a default region whose center point 
 *  is the location coordinate and whose span is 500 meters for both the latitudinal and longitudinal meters.
 *
 *  The specified block is executed upon completion of creating the snapshot image and is executed on the app’s main thread.
 *
 *  @param location   The location for the media item.
 *  @param completion The block to call after the map view snapshot for the given location has been created.
 */
- (void)setLocation:(CLLocation *)location withCompletionHandler:(ZNGLocationMediaItemCompletionBlock)completion;

/**
 *  Sets the specified location for the location media item and immediately begins creating
 *  a map view snapshot image on a background thread.
 *
 *  The specified block is executed upon completion of creating the snapshot image and is executed on the app’s main thread.
 *
 *  @param location   The location for the media item.
 *  @param region     The map region that you want to capture.
 *  @param completion The block to call after the map view snapshot for the given location has been created.
 */
- (void)setLocation:(CLLocation *)location
             region:(MKCoordinateRegion)region withCompletionHandler:(ZNGLocationMediaItemCompletionBlock)completion;
@end
