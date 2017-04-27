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
#import "ZNGLogging.h"
#import "ZNGContactFieldValue.h"
#import "ZNGContactField.h"
#import "ZNGFieldOption.h"

@import SDWebImage;

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGContactDefaultFieldsTableViewCell
{
    UIColor * defaultTextFieldBackgroundColor;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    defaultTextFieldBackgroundColor = self.firstNameField.backgroundColor;
    
    // Title picker
    UIPickerView * picker = [[UIPickerView alloc] init];
    picker.delegate = self;
    picker.dataSource = self;
    self.titleField.inputView = picker;
    
    // Make avatar round
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width / 2.0;
    self.avatarImageView.layer.masksToBounds = YES;
}

#pragma mark - Setters
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

- (void) setTitleFieldValue:(ZNGContactFieldValue *)titleFieldValue
{
    _titleFieldValue = titleFieldValue;
    self.titleField.text = titleFieldValue.value;
}

- (void) setFirstNameFieldValue:(ZNGContactFieldValue *)firstNameFieldValue
{
    _firstNameFieldValue = firstNameFieldValue;
    self.firstNameField.text = firstNameFieldValue.value;
}

- (void) setLastNameFieldValue:(ZNGContactFieldValue *)lastNameFieldValue
{
    _lastNameFieldValue = lastNameFieldValue;
    self.lastNameField.text = lastNameFieldValue.value;
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

#pragma mark -
- (void) applyChangesIfFirstResponder
{
    if (self.firstNameField.isFirstResponder) {
        self.firstNameFieldValue.value = self.firstNameField.text;
    } else if (self.lastNameField.isFirstResponder) {
        self.lastNameFieldValue.value = self.lastNameField.text;
    }
}

#pragma mark - Text field
- (void) textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.firstNameField) {
        self.firstNameFieldValue.value = self.firstNameField.text;
    } else if (textField == self.lastNameField) {
        self.lastNameFieldValue.value = self.lastNameField.text;
    }
}

#pragma mark - Title field
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.titleFieldValue.customField.options count];
}

- (NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (row >= [self.titleFieldValue.customField.options count]) {
        ZNGLogError(@"Out of bounds selecting a title option (%llu available)", (unsigned long long)[self.titleFieldValue.customField.options count]);
        return nil;
    }
    
    ZNGFieldOption * option = self.titleFieldValue.customField.options[row];
    return option.value;
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (row >= [self.titleFieldValue.customField.options count]) {
        ZNGLogError(@"Out of bounds selecting a title option (%llu available)", (unsigned long long)[self.titleFieldValue.customField.options count]);
        return;
    }
    
    ZNGFieldOption * option = self.titleFieldValue.customField.options[row];
    self.titleFieldValue.selectedCustomFieldOptionId = option.optionId;
    self.titleFieldValue.value = option.value;
    self.titleField.text = option.value;
}

@end
