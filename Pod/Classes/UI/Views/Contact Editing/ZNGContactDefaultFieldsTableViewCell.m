//
//  ZNGContactDefaultFieldsTableViewCell.m
//  Pods
//
//  Created by Jason Neel on 4/26/17.
//
//

#import "ZNGContactDefaultFieldsTableViewCell.h"
#import "JVFloatLabeledTextField.h"
#import "UIColor+ZingleSDK.h"
#import "ZNGAvatarImageView.h"
#import "NSString+Initials.h"
#import "ZNGContact.h"
#import "ZNGInitialsAvatar.h"
#import "UIFont+Lato.h"

@import SDWebImage;

@implementation ZNGContactDefaultFieldsTableViewCell
{
    UIColor * defaultTextFieldBackgroundColor;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    defaultTextFieldBackgroundColor = self.firstNameField.backgroundColor;
    
    // Make avatar round
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width / 2.0;
    self.avatarImageView.layer.masksToBounds = YES;
}

- (void) setContact:(ZNGContact *)contact
{
    _contact = contact;

    NSString * name = [NSString stringWithFormat:@"%@ %@", contact.firstNameFieldValue.value ?: @"", contact.lastNameFieldValue.value ?: @""];
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString * initials = [name initials];
    
    UIImage * placeholderImage;
    
    if ([initials length] > 0) {
        // We have initials for this contact.  Use that as a placeholder image and load any remote avatar.
        ZNGInitialsAvatar * initialsAvatar = [[ZNGInitialsAvatar alloc] initWithInitials:initials
                                                                               textColor:[UIColor zng_text_gray]
                                                                         backgroundColor:[UIColor zng_messageBubbleLightGrayColor]
                                                                                    size:self.avatarImageView.frame.size
                                                                                    font:[UIFont latoFontOfSize:20.0]];
        placeholderImage = [initialsAvatar avatarImage];
    } else {
        NSBundle * bundle = [NSBundle bundleForClass:[ZNGContactDefaultFieldsTableViewCell class]];
        placeholderImage = [UIImage imageNamed:@"anonymousAvatar" inBundle:bundle compatibleWithTraitCollection:nil];
    }
    
    [self.avatarImageView sd_setImageWithURL:contact.avatarUri placeholderImage:placeholderImage];
}

- (void) setEditingLocked:(BOOL)editingLocked
{
    [super setEditingLocked:editingLocked];
    
    self.titleField.enabled = !editingLocked;
    self.firstNameField.enabled = !editingLocked;
    self.lastNameField.enabled = !editingLocked;
    
    UIColor * backgroundColor = (editingLocked) ? [UIColor zng_light_gray] : defaultTextFieldBackgroundColor;
    self.titleField.backgroundColor = backgroundColor;
    self.firstNameField.backgroundColor = backgroundColor;
    self.lastNameField.backgroundColor = backgroundColor;
}



@end
