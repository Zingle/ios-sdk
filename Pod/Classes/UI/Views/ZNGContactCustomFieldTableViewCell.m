//
//  ZNGContactCustomFieldTableViewCell.m
//  Pods
//
//  Created by Jason Neel on 8/23/16.
//
//

#import "ZNGContactCustomFieldTableViewCell.h"
#import "ZNGContactFieldValue.h"
#import "ZNGLogging.h"
@import JVFloatLabeledTextField;

static const int zngLogLevel = ZNGLogLevelInfo;

@implementation ZNGContactCustomFieldTableViewCell
{
    UIPickerView * pickerView;
    UIDatePicker * datePicker;
}

- (void) setCustomFieldValue:(ZNGContactFieldValue *)customFieldValue
{
    ZNGLogVerbose(@"%@ custom field type set to %@, was %@", [self class], customFieldValue.customField.displayName, _customFieldValue.customField.displayName);
    
    _customFieldValue = customFieldValue;
    [self setupPickerViewIfNecessary];
    
    self.textField.placeholder = customFieldValue.customField.displayName;
    self.textField.text = customFieldValue.value;
}

- (void) setupPickerViewIfNecessary
{
    // Do we need a date picker?
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeTime]) {
        datePicker = [[UIDatePicker alloc] init];
        datePicker.datePickerMode = UIDatePickerModeTime;
    } else if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeDate]) {
        datePicker = [[UIDatePicker alloc] init];
        datePicker.datePickerMode = UIDatePickerModeDate;
    }
    
    [datePicker addTarget:self action:@selector(datePickerSelectionChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void) datePickerSelectionChanged:(id)sender
{
    
}

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeString]) {
        // We want a string.  We don't have to do anything special.
        textField.keyboardType = UIKeyboardTypeDefault;
        return YES;
    }
    
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeNumber]) {
        // Numbers only.
        textField.keyboardType = UIKeyboardTypeNumberPad;
        return YES;
    }
    
    
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    self.customFieldValue.value = textField.text;
}

@end
