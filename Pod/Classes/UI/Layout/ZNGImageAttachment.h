//
//  ZNGImageAttachment.h
//  Pods
//
//  Created by Jason Neel on 10/3/16.
//
//

#import <UIKit/UIKit.h>

@interface ZNGImageAttachment : NSTextAttachment

/**
 *  The maximum height of the image, to be considered along with the line fragment width.
 *
 *  Defaults to 120.
 */
@property (nonatomic, assign) CGFloat maxDisplayHeight;

@end
