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
    } else if (([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeSingleSelect]) || ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool])) {
        pickerView = [[UIPickerView alloc] init];
        pickerView.delegate = self;
        self.textField.inputView = pickerView;
    }
    
    if (datePicker != nil) {
        [datePicker addTarget:self action:@selector(datePickerSelectionChanged:) forControlEvents:UIControlEventValueChanged];
        self.textField.inputView = datePicker;
    }
}

- (void) datePickerSelectionChanged:(id)sender
{
    
}

#pragma mark - Picker view
- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString * value;
    
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        value = (row == 0) ? @"No" : @"Yes";
    } else {
        value = self.customFieldValue.customField.options[row];
    }
    
    self.textField.text = value;
}

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        return 2;
    }
    
    return [self.customFieldValue.customField.options count];
}

- (NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        if (row == 0) {
            return @"No";
        } else {
            return @"Yes";
        }
    }
    
    if (row >= [self.customFieldValue.customField.options count]) {
        ZNGLogError(@"Out of bounds when retrieving single select custom field picker options.  %lld >= our total of %llu options", (long long)row, (unsigned long long)[self.customFieldValue.customField.options count]);
        return nil;
    }
    
    return self.customFieldValue.customField.options[row];
}

#pragma mark - Text field delegate
//
//- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField
//{
//    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeString]) {
//        // We want a string.  We don't have to do anything special.
//        textField.keyboardType = UIKeyboardTypeDefault;
//        return YES;
//    }
//    
//    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeNumber]) {
//        // Numbers only.
//        textField.keyboardType = UIKeyboardTypeNumberPad;
//        return YES;
//    }
//    
//    
//}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    self.customFieldValue.value = textField.text;
}

@end
