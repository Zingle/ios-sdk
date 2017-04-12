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
    _rawImage = image;
    UIImage * finalImage = image;

    if ((self.showEditIcon) && (self.editIconImage != nil)) {
        finalImage = [self imageAddingEditIcon:image];
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
    CGSize superSize = [super intrinsicContentSize];
    CGFloat width = superSize.width - self.insetsWhenEditIconPresent.left - self.insetsWhenEditIconPresent.right;
    CGFloat height = superSize.height - self.insetsWhenEditIconPresent.top - self.insetsWhenEditIconPresent.bottom;
    return CGSizeMake(width, height);
}

#pragma mark - Image manipulation
- (UIImage *) imageAddingEditIcon:(UIImage *)image
{
    if ((image == nil) || (self.editIconImage == nil)) {
        return nil;
    }
    
    CGSize totalSize = [self intrinsicContentSize];
    
    // Draw the original image, allowing for padding
    UIGraphicsBeginImageContextWithOptions(totalSize, false, image.scale);
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
