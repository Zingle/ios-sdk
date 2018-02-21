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
#import "ZNGGooglyEye.h"
#import "ZNGAnalytics.h"

@import SDWebImage;

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGContactDefaultFieldsTableViewCell
{
    UIColor * defaultTextFieldBackgroundColor;
    BOOL justClearedTitle;
    
    __weak NSTimer * logEasterEggTimer;
    
    ZNGGooglyEye * leftEye;
    ZNGGooglyEye * rightEye;
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
    
    // Googly eye touching
    UILongPressGestureRecognizer * eyeToucher = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(touchedAvatar:)];
    eyeToucher.minimumPressDuration = 0.0;  // Instant on touch down
    self.avatarImageView.userInteractionEnabled = YES;
    [self.avatarImageView addGestureRecognizer:eyeToucher];
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
        // We have initials for this contact.  Use that as a placeholder image.
        ZNGInitialsAvatar * initialsAvatar = [[ZNGInitialsAvatar alloc] initWithInitials:initials
                                                                               textColor:[UIColor zng_text_gray]
                                                                         backgroundColor:[UIColor zng_messageBubbleLightGrayColor]
                                                                                    size:self.avatarImageView.frame.size
                                                                                    font:[UIFont latoFontOfSize:20.0]];
        placeholderImage = [initialsAvatar avatarImage];
    } else {
        // We have no initials for this user.  Use the anonymous avatar image as a placeholder.
        NSBundle * bundle = [NSBundle bundleForClass:[ZNGContactDefaultFieldsTableViewCell class]];
        placeholderImage = [UIImage imageNamed:@"anonymousAvatarBig" inBundle:bundle compatibleWithTraitCollection:nil];
    }
    
    [self.avatarImageView sd_setImageWithURL:contact.avatarUri placeholderImage:placeholderImage];
}

- (void) setTitleFieldValue:(ZNGContactFieldValue *)titleFieldValue
{
    _titleFieldValue = titleFieldValue;
    self.titleField.text = titleFieldValue.value;
    
    UIPickerView * pickerView = (UIPickerView *)self.titleField.inputView;
    
    if ([titleFieldValue.value length] > 0) {
        // Attempt to find the current value in the set of options
        __block BOOL weDidIt = NO;
        [titleFieldValue.customField.options enumerateObjectsUsingBlock:^(ZNGFieldOption * _Nonnull option, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([option.value isEqualToString:titleFieldValue.value]) {
                [pickerView selectRow:idx inComponent:0 animated:NO];
                weDidIt = YES;
                *stop = YES;
            }
        }];
        
        if (weDidIt) {
            return;
        }
    }
    
    // Either there is no value set in the custom field or we were unable to find an option matching the current value.
    // Select the first option.
    [pickerView selectRow:0 inComponent:0 animated:NO];
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

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
    // Pressing the clear button in the title field should not bring up the title selections.
    if ((textField == self.titleField) && (justClearedTitle)) {
        justClearedTitle = NO;
        return NO;
    }
    
    return YES;
}

- (BOOL) textFieldShouldClear:(UITextField *)textField
{
    if (textField == self.titleField) {
        self.titleFieldValue.value = nil;
        justClearedTitle = YES;
    }
    
    return YES;
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
        ZNGLogError(@"Out of bounds displaying a title option (%llu available)", (unsigned long long)[self.titleFieldValue.customField.options count]);
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

#pragma mark - Eye touching
- (void) touchedAvatar:(UILongPressGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            if ((leftEye.superview != nil) || (rightEye.superview != nil)) {
                ZNGLogInfo(@"A googly eye already seems to exist.  Declining to make another.");
                return;
            }
            
            // If the user keeps his finger down for more than one second, consider it an easter egg action for analytics
            logEasterEggTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(notifyEggHeldLongEnoughToCount:) userInfo:nil repeats:NO];
            
            leftEye = [[ZNGGooglyEye alloc] initWithFrame:self.leftEyeContainer.bounds];
            rightEye = [[ZNGGooglyEye alloc] initWithFrame:self.rightEyeContainer.bounds];
            [self.leftEyeContainer addSubview:leftEye];
            [self.rightEyeContainer addSubview:rightEye];
            break;
            
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
            [logEasterEggTimer invalidate];
            logEasterEggTimer = nil;
            
            [leftEye removeFromSuperview];
            [rightEye removeFromSuperview];
            leftEye = nil;
            rightEye = nil;
            break;
            
        default:
            // Irrelevant
            break;
    }
}

- (void) notifyEggHeldLongEnoughToCount:(NSTimer *)timer
{
    [[ZNGAnalytics sharedAnalytics] trackEasterEggNamed:@"Edit contact avatar"];
}

@end
