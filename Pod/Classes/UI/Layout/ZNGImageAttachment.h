//
//  ZNGImageAttachment.h
//  Pods
//
//  Created by Jason Neel on 10/3/16.
//
//

#import <UIKit/UIKit.h>

@interface ZNGImageAttachment : NSTextAttachment
{
    CGFloat _imageScale;
}

/**
 *  The maximum height of the image, to be considered along with the line fragment width.
 *
 *  Defaults to 120.
 */
@property (nonatomic, assign) CGFloat maxDisplayHeight;

/**
 *  This scale is adjusted internally whenever a draw call is made.  It is only public so subclasses can override the property.
 */
@property (nonatomic, assign) CGFloat imageScale;

@end
