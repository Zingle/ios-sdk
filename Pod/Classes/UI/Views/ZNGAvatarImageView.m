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
        ZNGInitialsAvatar * initialsAvatar = [[ZNGInitialsAvatar alloc] initWithInitials:initials textColor:textColor backgroundColor:backgroundColor size:size font:font];
        UIImage * initialsImage = [initialsAvatar avatarImage];
        
        [self sd_setImageWithURL:avatarUrl placeholderImage:initialsImage];
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
    return CGSizeMake(superSize.width + (self.editImageEdgeOverflow.x * 2.0), superSize.height + (self.editImageEdgeOverflow.y * 2.0));
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
    [image drawAtPoint:self.editImageEdgeOverflow];
    
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
