//
//  ZNGAvatarImageView.m
//  Pods
//
//  Created by Jason Neel on 4/11/17.
//
//

#import "ZNGAvatarImageView.h"
#import "ZNGInitialsAvatar.h"
#import "UIImage+CircleCrop.h"

@import SBObjectiveCWrapper;
@import SDWebImage;

@implementation ZNGAvatarImageView
{
    /**
     *  The image set before any edit icon was possibly added.
     */
    UIImage * _rawImage;
}

#pragma mark - Initialization
- (id) initWithAvatarUrl:(NSURL * _Nullable)avatarUrl initials:(NSString *)initials size:(CGSize)size backgroundColor:(UIColor * _Nullable)backgroundColor textColor:(UIColor *)textColor font:(UIFont *)font;
{
    self = [super init];
    
    if (self != nil) {
        _avatarUrl = [avatarUrl copy];
        _initials = [initials copy];
        _size = size;
        _avatarBackgroundColor = backgroundColor;
        _textColor = textColor;
        _font = font;
        
        ZNGInitialsAvatar * initialsAvatar = [[ZNGInitialsAvatar alloc] initWithInitials:initials textColor:textColor backgroundColor:backgroundColor size:size font:font];
        _placeholderImage = [initialsAvatar avatarImage];
        
        self.frame = CGRectMake(0.0, 0.0, size.width, size.height);
        self.contentMode = UIViewContentModeScaleAspectFit;
        
        [self sd_setImageWithURL:avatarUrl placeholderImage:_placeholderImage];
    }
    
    return self;
}

#pragma mark - Getters/Setters
- (void) setShowEditIcon:(BOOL)showEditIcon
{
    if (self.showEditIcon == showEditIcon) {
        return;
    }
    
    _showEditIcon = showEditIcon;
    
    if (showEditIcon) {
        [super setImage:[self imageAddingEditIcon:_rawImage]];
    } else {
        [super setImage:_rawImage];
    }
}

- (void) setEditIconImage:(UIImage *)editIconImage
{
    _editIconImage = editIconImage;
    
    if (self.showEditIcon) {
        // We need to re-render
        [super setImage:[self imageAddingEditIcon:_rawImage]];
    }
}

- (void) setImage:(UIImage *)image
{
    _rawImage = [self imageCroppedToCircle:image];;
    UIImage * finalImage = _rawImage;

    if ((self.showEditIcon) && (self.editIconImage != nil)) {
        finalImage = [self imageAddingEditIcon:_rawImage];
    }
    
    [super setImage:finalImage];
}

- (void) setCenterOfImage:(CGPoint)centerOfImage
{
    if ((!self.showEditIcon) || (self.editIconImage == nil)) {
        self.center = centerOfImage;
        return;
    }
    
    CGPoint boundsCenter = [self convertPoint:centerOfImage fromView:self.superview];
    CGFloat boundsX = boundsCenter.x + self.insetsWhenEditIconPresent.left - (_rawImage.size.width / 2.0);
    CGFloat boundsY = boundsCenter.y + self.insetsWhenEditIconPresent.top - (_rawImage.size.height  /2.0);
    CGFloat boundsWidth = _rawImage.size.width - self.insetsWhenEditIconPresent.left - self.insetsWhenEditIconPresent.right;
    CGFloat boundsHeight = _rawImage.size.height - self.insetsWhenEditIconPresent.bottom - self.insetsWhenEditIconPresent.top;
    
    CGRect newBounds = CGRectMake(boundsX, boundsY, boundsWidth, boundsHeight);
    CGPoint newBoundsCenter = CGPointMake(CGRectGetMidX(newBounds), CGRectGetMidY(newBounds));
    CGPoint newCenter = [self convertPoint:newBoundsCenter toView:self.superview];
    
    SBLogDebug(@"%@ %p: Request to set centerOfImage to %@ results in setting center to %@", [self class], self, NSStringFromCGPoint(centerOfImage), NSStringFromCGPoint(newCenter));
    
    self.center = newCenter;
}

- (CGPoint) centerOfImage
{
    if ((!self.showEditIcon) || (self.editIconImage == nil)) {
        return self.center;
    }
    
    CGFloat boundsCenterX = self.bounds.size.width + self.insetsWhenEditIconPresent.right - (_rawImage.size.width / 2.0);
    CGFloat boundsCenterY = self.bounds.size.height + self.insetsWhenEditIconPresent.bottom - (_rawImage.size.height / 2.0);
    CGPoint boundsCenter = CGPointMake(boundsCenterX, boundsCenterY);
    
    CGPoint centerOfImage = [self convertPoint:boundsCenter toView:self.superview];
    
    SBLogDebug(@"%@ %p: Current center is %@, making centerOfImage %@", [self class], self, NSStringFromCGPoint(self.center), NSStringFromCGPoint(centerOfImage));
    
    return centerOfImage;
}

#pragma mark - Sizing
- (CGSize) intrinsicContentSize
{
    if (!self.showEditIcon) {
        // No edit icon = nothing special about our subclass
        return [super intrinsicContentSize];
    }

    CGFloat width = _rawImage.size.width - self.insetsWhenEditIconPresent.left - self.insetsWhenEditIconPresent.right;
    CGFloat height = _rawImage.size.height - self.insetsWhenEditIconPresent.top - self.insetsWhenEditIconPresent.bottom;
    return CGSizeMake(width, height);
}

#pragma mark - Image manipulation
- (UIImage *) imageCroppedToCircle:(UIImage * )image
{
    if (image == nil) {
        return nil;
    }
    
    CGFloat diameter = MIN(self.size.width, self.size.height);
    return [image imageCroppedToCircleOfDiameter:diameter withScale:0.0];
}

- (UIImage *) imageAddingEditIcon:(UIImage *)image
{
    if ((image == nil) || (self.editIconImage == nil)) {
        return nil;
    }
    
    CGSize totalSize = [self intrinsicContentSize];
    
    // Draw the original image, allowing for padding
    UIGraphicsBeginImageContextWithOptions(totalSize, false, 0.0);
    CGPoint originalImageOrigin = CGPointMake(-self.insetsWhenEditIconPresent.left, -self.insetsWhenEditIconPresent.top);
    [image drawAtPoint:originalImageOrigin];
    
    // Draw the edit icon
    [self.editIconImage drawAtPoint:[self editImageLocation]];
    
    UIImage * result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

- (CGPoint) editImageLocation
{
    CGSize totalSize = [self intrinsicContentSize];
    return CGPointMake(totalSize.width - self.editIconImage.size.width, totalSize.height - self.editIconImage.size.height);
}


@end
