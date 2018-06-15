//
//  ZNGImageAttachmentController.h
//  ZingleSDK
//
//  Created by Jason Neel on 6/6/18.
//

#import <UIKit/UIKit.h>

@class ZNGImageAttachmentController;

NS_ASSUME_NONNULL_BEGIN

@protocol ZNGImageAttachmentDelegate

@optional

/**
 *  The controller was either dismissed or encountered a failure.  In case of failure, the controller will present
 *   an error dialog to the user itself, so no UI action is required by the delegate.
 */
- (void) imageAttachmentControllerDismissedWithoutSelection:(ZNGImageAttachmentController *)controller;

@required

/**
 *  Provides the delegate with both a UIImage and NSData for the image that the user took/selected.  Supports animated GIFs.
 */
- (void) imageAttachmentController:(ZNGImageAttachmentController *)controller selectedImage:(UIImage *)image imageData:(NSData *)imageData;

@end

/**
 *  An image attachment controller encapsultes the process of asking the user to take a photo or select an image and processing
 *   the result, supporting animated GIFs and varying versions of iOS and user permissions as required.
 */
@interface ZNGImageAttachmentController : NSObject <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

/**
 *  Initializes the image attachment controller.  If no popover source/rect is provided on an iPad, action sheets will instead
 *   be shown as alerts.  If popoverRect is CGRectZero, popoverSource.bounds will be used.
 */
- (nullable id) initWithDelegate:(NSObject <ZNGImageAttachmentDelegate> *)delegate popoverSource:(nullable UIView *)popoverSource popoverRect:(CGRect)popoverRect;

/**
 *  Begins by asking the user to attach a photo via camera or photo library.
 *  Once the user either cancels, selects a photo, or takes a new photo, the delegate will be provided
 *   a UIImage and NSData object for the selected image.
 *
 *  @param viewController The view controller from which to present all UI.  It will be used throughout the process but is not strongly retained.
 */
- (void) startFromViewController:(UIViewController *)viewController;

@property (nonatomic, weak, nullable) NSObject <ZNGImageAttachmentDelegate> * delegate;

@end

NS_ASSUME_NONNULL_END
