//
//  ZNGContactPhoneNumberTableViewCell.m
//  Pods
//
//  Created by Jason Neel on 8/24/16.
//
//

#import "ZNGContactPhoneNumberTableViewCell.h"
#import "ZNGChannel.h"
#import "ZNGService.h"
#import "UIColor+ZingleSDK.h"
@import JVFloatLabeledTextField;

@implementation ZNGContactPhoneNumberTableViewCell
{
    UIColor * defaultTextFieldBackgroundColor;
    UIColor * lockedBackgroundColor;
    UIImageView * lockedRightView;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.textField.rightViewMode = UITextFieldViewModeAlways;
    
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    UIImage * lockImage = [UIImage imageNamed:@"lock" inBundle:bundle compatibleWithTraitCollection:nil];
    lockedRightView = [[UIImageView alloc] initWithImage:lockImage];
    lockedRightView.contentMode = UIViewContentModeCenter;
    lockedRightView.tintColor = [UIColor lightGrayColor];
    
    defaultTextFieldBackgroundColor = self.textField.backgroundColor;
    lockedBackgroundColor = [UIColor colorNamed:@"ZNGDisabledBackground" inBundle:bundle compatibleWithTraitCollection:nil];
}

- (void) setService:(ZNGService *)service
{
    _service = service;
    [self updateTextField];
}

- (void) setChannel:(ZNGChannel *)channel
{
    _channel = channel;
    [self updateTextField];
}

- (void) setEditingLocked:(BOOL)editingLocked
{
    [super setEditingLocked:editingLocked];
    [self updateTextField];
}

- (void) updateTextField
{
    self.textField.enabled = !self.editingLocked;
    self.textField.rightView = (self.editingLocked) ? lockedRightView : nil;
    self.textField.backgroundColor = (self.editingLocked) ? lockedBackgroundColor : defaultTextFieldBackgroundColor;
    
    NSString * value = ([self.service shouldDisplayRawValueForChannel:self.channel]) ? self.channel.value : self.channel.formattedValue;
    self.textField.text = value;
}

- (void) applyInProgressChanges
{
    if ([self.textField isFirstResponder]) {
        [self.channel setValueFromTextEntry:self.textField.text];
    }
}

#pragma mark - Actions
- (IBAction)pressedDelete:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(userClickedDeleteOnPhoneNumberTableCell:)]) {
        [self.delegate userClickedDeleteOnPhoneNumberTableCell:self];
    }
}

#pragma mark - Text view delegate
- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Only allow phone number characters
    NSCharacterSet * phoneNumberCharacters = [NSCharacterSet characterSetWithCharactersInString:@"0123456789-() *#+"];
    NSCharacterSet * disallowedCharacters = [phoneNumberCharacters invertedSet];
    NSRange disallowedRange = [string rangeOfCharacterFromSet:disallowedCharacters];
    return (disallowedRange.location == NSNotFound);
}

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    // We are probably displaying a formatted form, e.g. (703) 555-1212.
    // We want to display 7035551212 or even +17035551212 when they begin editing.
    if ([self.channel.value length] > 0) {
        self.textField.text = self.channel.value;
    }
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    [self.channel setValueFromTextEntry:textField.text];
}

@end
