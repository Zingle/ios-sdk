//
//  ZNGAvatarImageView.m
//  Pods
//
//  Created by Jason Neel on 4/11/17.
//
//

#import "ZNGAvatarImageView.h"
#import "ZNGInitialsAvatar.h"

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
        _backgroundColor = backgroundColor;
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

#pragma mark - Setters
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

#pragma mark - Sizing
- (CGSize) intrinsicContentSize
{
    if (!self.showEditIcon) {
        // No edit icon = nothing special about our subclass
        return [super intrinsicContentSize];
    }

    // Note that expandedSize adds double x and y of the overflow.  This is so our original image asset remains centered, even after adding overflow
    //  for the edit icon.
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
    CGFloat smallestDimension = MIN(image.size.width, image.size.height);
    CGFloat scale = diameter / smallestDimension;
    CGFloat scaledSmallestDimension = smallestDimension * scale;
    
    CGSize downscaledSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(scaledSmallestDimension, scaledSmallestDimension), false, 0.0);
    CGRect rect = CGRectMake(0.0, 0.0, scaledSmallestDimension, scaledSmallestDimension);
    [[UIBezierPath bezierPathWithOvalInRect:rect] addClip];
    CGFloat radius = scaledSmallestDimension / 2.0;
    CGFloat halfWidth = downscaledSize.width / 2.0;
    CGFloat halfHeight = downscaledSize.height / 2.0;
    CGPoint imageOrigin = CGPointMake(radius - halfWidth, radius - halfHeight);
    
    [image drawInRect:CGRectMake(imageOrigin.x, imageOrigin.y, downscaledSize.width, downscaledSize.height)];
    
    UIImage * result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
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
