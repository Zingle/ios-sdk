//
//  ZNGContactChannelTableViewCell.m
//  Pods
//
//  Created by Jason Neel on 8/24/16.
//
//

#import "ZNGContactChannelTableViewCell.h"
#import "ZNGChannel.h"
@import JVFloatLabeledTextField;

@implementation ZNGContactChannelTableViewCell

- (void) setChannel:(ZNGChannel *)channel
{
    _channel = [channel copy];
    
    self.textField.placeholder = channel.channelType.displayName;
    self.textField.text = channel.formattedValue;
    
    if ([channel.channelType isPhoneNumberType]) {
        self.textField.keyboardType = UIKeyboardTypeNumberPad;
    } else if ([channel.channelType isEmailType]) {
        self.textField.keyboardType = UIKeyboardTypeEmailAddress;
    } else {
        self.textField.keyboardType = UIKeyboardTypeDefault;
    }
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    [self.channel setValueFromTextEntry:textField.text];
}

@end
