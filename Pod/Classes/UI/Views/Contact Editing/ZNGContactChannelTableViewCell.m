//
//  ZNGContactChannelTableViewCell.m
//  Pods
//
//  Created by Jason Neel on 8/24/16.
//
//

#import "ZNGContactChannelTableViewCell.h"
#import "ZNGChannel.h"
#import "UIColor+ZingleSDK.h"
@import JVFloatLabeledTextField;

@implementation ZNGContactChannelTableViewCell
{
    UIColor * defaultBackgroundColor;
    UIColor * lockedBackgroundColor;
    UIView * lockedRightView;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGContactChannelTableViewCell class]];
    UIImage * lockedImage = [UIImage imageNamed:@"lock" inBundle:bundle compatibleWithTraitCollection:nil];
    lockedRightView = [[UIImageView alloc] initWithImage:lockedImage];
    lockedRightView.contentMode = UIViewContentModeCenter;
    lockedRightView.tintColor = [UIColor lightGrayColor];
    
    defaultBackgroundColor = self.textField.backgroundColor;
    lockedBackgroundColor = [UIColor colorNamed:@"ZNGDisabledBackground" inBundle:bundle compatibleWithTraitCollection:nil];
    
    self.textField.rightViewMode = UITextFieldViewModeAlways;
}

- (void) setEditingLocked:(BOOL)editingLocked
{
    [super setEditingLocked:editingLocked];
    [self updateUI];
}

- (void) applyChangesIfFirstResponder
{
    if ([self.textField isFirstResponder]) {
        [self.channel setValueFromTextEntry:self.textField.text];
    }
}

- (void) setChannel:(ZNGChannel *)channel
{
    _channel = channel;
    [self updateUI];
}

- (void) updateUI
{
    UIView * rightView = (self.editingLocked) ? lockedRightView : nil;
    UIColor * backgroundColor = (self.editingLocked) ? lockedBackgroundColor : defaultBackgroundColor;
    
    self.textField.placeholder = self.channel.channelType.displayName;
    self.textField.text = self.channel.formattedValue;
    self.textField.backgroundColor = backgroundColor;
    self.textField.rightView = rightView;
    self.textField.enabled = !self.editingLocked;
    
    if ([self.channel.channelType isPhoneNumberType]) {
        self.textField.keyboardType = UIKeyboardTypeNumberPad;
    } else if ([self.channel.channelType isEmailType]) {
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
