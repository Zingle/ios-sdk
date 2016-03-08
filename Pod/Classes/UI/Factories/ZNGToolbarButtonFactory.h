//
//  ZNGToolbarButtonFactory.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  `ZNGToolbarButtonFactory` is a factory that provides a means for creating the default
 *  toolbar button items to be displayed in the content view of a `ZNGInputToolbar`.
 */
@interface ZNGToolbarButtonFactory : NSObject

/**
 *  Creates and returns a new button that is styled as the default accessory button. 
 *  The button has a paper clip icon image and no text.
 *
 *  @return A newly created button.
 */
+ (UIButton *)defaultAccessoryButtonItem;

/**
 *  Creates and returns a new button that is styled as the default send button. 
 *  The button has title text `@"Send"` and no image.
 *
 *  @return A newly created button.
 */
+ (UIButton *)defaultSendButtonItem;

@end
