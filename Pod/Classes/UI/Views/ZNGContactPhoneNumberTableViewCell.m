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
@import JVFloatLabeledTextField;

@implementation ZNGContactPhoneNumberTableViewCell

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

- (void) updateTextField
{
    self.textField.text = (self.service != nil) ? [self.service displayNameForChannel:self.channel] : self.channel.formattedValue;
}

- (void) applyChangesIfFirstResponder
{
    if ([self.textField isFirstResponder]) {
        [self.channel setValueFromTextEntry:self.textField.text];
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
