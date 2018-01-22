//
//  UIImage+CircleCrop.h
//  ZingleSDK
//
//  Created by Jason Neel on 1/22/18.
//

#import <UIKit/UIKit.h>

@interface UIImage (CircleCrop)

/**
 *  The image resized and cropped to fit within a circle.
 *
 *  @param diameter The desired diameter in points
 *  @param scale The scale factor of the resulting image.  0.0 will use the device's main screen scale value.
 */
- (UIImage *) imageCroppedToCircleOfDiameter:(CGFloat)diameter withScale:(CGFloat)scale;

@end
