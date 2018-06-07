//
//  ZNGImageAttachmentController.m
//  ZingleSDK
//
//  Created by Jason Neel on 6/6/18.
//

#import "ZNGImageAttachmentController.h"
#import "UIImage+animatedGIF.h"

@import Photos;
@import SBObjectiveCWrapper;

@implementation ZNGImageAttachmentController
{
    __weak UIViewController * hostViewController;
    __weak UIView * popoverSource;
    CGRect _popoverRect;
}

- (nullable id) initWithDelegate:(NSObject <ZNGImageAttachmentDelegate> *)delegate popoverSource:(nullable UIView *)thePopoverSource popoverRect:(CGRect)thePopoverRect
{
    self = [super init];
    
    if (self != nil) {
        _delegate = delegate;
        popoverSource = thePopoverSource;
        _popoverRect = thePopoverRect;
        
        if (![self verifyActionSheetAbility]) {
            SBLogError(@"%@ initialized on an iPad without popover information.  This makes displaying a photo picker impossible.", [self class]);
            return nil;
        }
    }
    
    return self;
}

- (BOOL) verifyActionSheetAbility
{
    BOOL isIpad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    
    if ((isIpad) && (popoverSource == nil)) {
        return NO;
    }
    
    // Either this is not an iPad or we have all of the popover display info we need to avoid crashing
    return YES;
}

- (CGRect) popoverRect
{
    return (CGRectEqualToRect(_popoverRect, CGRectZero)) ? popoverSource.bounds : _popoverRect;
}

- (void) startFromViewController:(UIViewController *)viewController
{
    hostViewController = viewController;
    
    UIAlertControllerStyle alertStyle = UIAlertControllerStyleActionSheet;
    
    if (![self verifyActionSheetAbility]) {
        // We'll do our best to continue along without popover info.  Things are going to be weird/broken if the user tries
        //  to attach an existing photo.  That UI is supposed to be a popover on iPad, per UIKit documentation.
        SBLogError(@"%s was called, but we are missing source info for an action sheet.  An alert will be used instead.", __PRETTY_FUNCTION__);
        alertStyle = UIAlertControllerStyleAlert;
    }
    
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:alertStyle];
    
    alert.popoverPresentationController.sourceView = popoverSource;
    alert.popoverPresentationController.sourceRect = [self popoverRect];
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        SBLogInfo(@"The user's current device does not have a camera, does not allow camera access, or the camera is currently unavailable.");
    } else {
        UIAlertAction * takePhoto = [UIAlertAction actionWithTitle:@"Take a photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showImagePickerWithCameraMode:YES];
        }];
        [alert addAction:takePhoto];
    }
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        SBLogInfo(@"The user's photo library is currently not available or is empty.");
    } else {
        UIAlertAction * choosePhoto = [UIAlertAction actionWithTitle:@"Choose a photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showImagePickerWithCameraMode:NO];
        }];
        [alert addAction:choosePhoto];
    }
    
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    
    [hostViewController presentViewController:alert animated:YES completion:nil];
}

- (void) showImageAttachmentError
{
    [hostViewController dismissViewControllerAnimated:NO completion:^{
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Unable to load image" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [self->hostViewController presentViewController:alert animated:NO completion:^{
            if ([self.delegate respondsToSelector:@selector(imageAttachmentControllerDismissedWithoutSelection:)]) {
                [self.delegate imageAttachmentControllerDismissedWithoutSelection:self];
            }
        }];
    }];
}

/**
 *  Shows an image picker.
 *
 *  @param cameraMode If YES, the image picker will be initialized with UIImagePickerControllerSourceTypeCamera, otherwise UIImagePickerControllerSourceTypePhotoLibrary
 */
- (void) showImagePickerWithCameraMode:(BOOL)cameraMode
{
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = cameraMode ? UIImagePickerControllerSourceTypeCamera : UIImagePickerControllerSourceTypePhotoLibrary;
    
    // For iPads showing the photo library, the UIImagePickerController must be presented as a popover (per UIImagePickerController documentation).
    if ((!cameraMode) && ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)) {
        picker.modalPresentationStyle = UIModalPresentationPopover;
        picker.popoverPresentationController.sourceView = popoverSource;
        picker.popoverPresentationController.sourceRect = [self popoverRect];
    }
    
    [hostViewController presentViewController:picker animated:YES completion:nil];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    if (info[UIImagePickerControllerReferenceURL] != nil) {
        // This is from the photo library.  We can load it from there.
        [self attachImageFromPhotoLibraryWithInfo:info];
    } else if (info[UIImagePickerControllerOriginalImage] != nil) {
        // This is probably straight from the camera; we do not have PH asset info to go along with the image.
        [self attachImageWithInfo:info];
    } else {
        SBLogError(@"Image picker did not return any any \"original image\" data.");
        [self showImageAttachmentError];
    }
}

- (void) attachImageWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage * image = info[UIImagePickerControllerOriginalImage];
    
    if (image == nil) {
        [self showImageAttachmentError];
        return;
    }
    
    NSData * imageData = UIImageJPEGRepresentation(image, 0.75);
    
    if (hostViewController != nil) {
        [hostViewController dismissViewControllerAnimated:YES completion:^{
            [self.delegate imageAttachmentController:self selectedImage:image imageData:imageData];
        }];
    } else {
        [self.delegate imageAttachmentController:self selectedImage:image imageData:imageData];
    }
}

- (void) attachImageFromPhotoLibraryWithInfo:(NSDictionary<NSString *,id> *)info
{
    // Retrieve the selected image to verify that we are starting with something.
    // This UIImage may be insufficient, such as is the case with animated GIFs (where we only get one frame here).
    UIImage * image = info[UIImagePickerControllerOriginalImage];
    
    if (image == nil) {
        SBLogError(@"The user selected an image, but no image was found in the callback info dictionary.  What are we supposed to do now?");
        [self showImageAttachmentError];
        return;
    }
    
    PHAsset * asset;
    
    // If we're in iOS 11 and have already sought photo library access permission, we will immediately get the PHAsset here.
    if (@available(iOS 11.0, *)) {
        asset = info[UIImagePickerControllerPHAsset];
    }
    
    if (asset != nil) {
        // That was easy
        [self attachImageWithAsset:asset];
        return;
    }
    
    // Otherwise, we are either pre iOS 11 or do not yet have permission.  Either way, we get to go on a trip to PHPhotoLibrary town.
    // First, ensure that we have an image URL that we can later use with PHImageManager.
    // Note that UIImagePickerControllerReferenceURL is supposed to be deprecated in iOS 11, but I cannot find any other way to access
    //  the PHAsset passed in the image picker callback the very first time it is done.  The alternative is to ask the user for permission
    //  for photo library access up front before an image is selected.  That would avoid a deprecated dictionary key at the expense of a
    //  slightly worse user experience.
    NSURL * url = info[UIImagePickerControllerReferenceURL];
    
    if (url == nil) {
        SBLogError(@"The user selected an image, but we did not receieve a reference URL to retrieve it.  Drat.");
        [self showImageAttachmentError];
        return;
    }
    
    // In the cases that we already have permission, this extra call to request permission will have no visible effect.
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) {
            SBLogError(@"The user has not granted us permission to use an image from their library.  Silly human.");
            
            if ([self.delegate respondsToSelector:@selector(imageAttachmentControllerDismissedWithoutSelection:)]) {
                [self.delegate imageAttachmentControllerDismissedWithoutSelection:self];
            }
            
            return;
        }
        
        PHAsset * asset = [[PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil] lastObject];
        
        if (asset == nil) {
            SBLogError(@"Unable to retrieve the selected image asset from disk.  Odd.");
            [self showImageAttachmentError];
            return;
        }
        
        [self attachImageWithAsset:asset];
    }];
}

- (void) attachImageWithAsset:(PHAsset *)asset
{
    PHImageRequestOptions * options = [[PHImageRequestOptions alloc] init];
    options.synchronous = NO;
    options.networkAccessAllowed = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if ([imageData length] == 0) {
            // We did not get image data.  Show an error.
            [self showImageAttachmentError];
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage * image = [UIImage animatedImageWithAnimatedGIFData:imageData];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self->hostViewController != nil) {
                        [self->hostViewController dismissViewControllerAnimated:YES completion:^{
                            [self.delegate imageAttachmentController:self selectedImage:image imageData:imageData];
                        }];
                    } else {
                        [self.delegate imageAttachmentController:self selectedImage:image imageData:imageData];
                    }
                });
            });
        }
    }];
}


@end
