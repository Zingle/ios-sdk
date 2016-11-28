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
#import "ZNGFieldOption.h"
#import "UIColor+ZingleSDK.h"

@import JVFloatLabeledTextField;

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGContactCustomFieldTableViewCell
{
    UIPickerView * pickerView;
    UIDatePicker * datePicker;
    
    NSDateFormatter * dateFormatter;
    NSDateFormatter * _timeFormatter;
    
    UIColor * defaultTextFieldBackgroundColor;
    
    BOOL numericOnly;
    BOOL justClearedDateOrTime;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    defaultTextFieldBackgroundColor = self.textField.backgroundColor;
}

- (void) prepareForReuse
{
    [super prepareForReuse];
    pickerView = nil;
    datePicker = nil;
    self.textField.inputView = nil;
    self.textField.text = @"";
    self.textField.placeholder = @"";
    numericOnly = NO;
}

- (NSString *) displayStringForDate:(NSDate *)date
{
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    
    return [dateFormatter stringFromDate:date];
}

- (void) setEditingLocked:(BOOL)editingLocked
{
    [super setEditingLocked:editingLocked];
    [self updateDisplay];
}

- (void) setCustomFieldValue:(ZNGContactFieldValue *)customFieldValue
{
    ZNGLogVerbose(@"%@ custom field type set to %@ (type %@), was %@", [self class], customFieldValue.customField.displayName, customFieldValue.customField.dataType, _customFieldValue.customField.displayName);
    
    _customFieldValue = customFieldValue;
    
    [self configureInput];
    [self updateDisplay];
}

- (void) updateDisplay
{
    self.textField.enabled = !self.editingLocked;
    self.textField.backgroundColor = (self.editingLocked) ? [UIColor zng_light_gray] : defaultTextFieldBackgroundColor;
    self.textField.placeholder = self.customFieldValue.customField.displayName;
    
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeDate]) {
        if ([self.customFieldValue.value length] > 0) {
            double dateUTCDouble = [self.customFieldValue.value doubleValue];
            NSDate * date = [NSDate dateWithTimeIntervalSince1970:dateUTCDouble];
            datePicker.date = date;
            self.textField.text = [self displayStringForDate:date];
        } else {
            self.textField.text = @"";
        }
    } else {
        
        if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeTime]) {
            datePicker.date = [self dateObjectForTimeString:self.customFieldValue.value];
        } else {
            NSUInteger index = [self indexOfCurrentValue];
            
            if (index != NSNotFound) {
                [pickerView selectRow:index inComponent:0 animated:NO];
            }
        }
        
        NSString * value = self.customFieldValue.value;
        
        if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
            BOOL asBool = [self.customFieldValue.value boolValue];
            value = asBool ? @"Yes" : @"No";
        }
        
        self.textField.text = value;
    }
}

- (void) configureInput
{
    BOOL optionsExist = [self.customFieldValue.customField.options count] > 0;
    
    // Do we need a picker?
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeTime]) {
        self.textField.clearButtonMode = UITextFieldViewModeAlways;
        datePicker = [[UIDatePicker alloc] init];
        datePicker.datePickerMode = UIDatePickerModeTime;
        [datePicker addTarget:self action:@selector(datePickerSelectedTime:) forControlEvents:UIControlEventValueChanged];
        self.textField.inputView = datePicker;
    } else if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeDate]) {
        self.textField.clearButtonMode = UITextFieldViewModeAlways;
        datePicker = [[UIDatePicker alloc] init];
        datePicker.datePickerMode = UIDatePickerModeDate;
        datePicker.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [datePicker addTarget:self action:@selector(datePickerSelectedDate:) forControlEvents:UIControlEventValueChanged];
        self.textField.inputView = datePicker;

    } else if ((optionsExist) || ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool])) {
        self.textField.clearButtonMode = UITextFieldViewModeNever;
        pickerView = [[UIPickerView alloc] init];
        pickerView.delegate = self;
        pickerView.dataSource = self;
        self.textField.inputView = pickerView;
    } else {
        self.textField.clearButtonMode = UITextFieldViewModeNever;

        // This is text input
        // Is it numeric or text?
        if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeNumber]) {
            self.textField.keyboardType = UIKeyboardTypeNumberPad;
            numericOnly = YES;
        } else {
            self.textField.keyboardType = UIKeyboardTypeDefault;
            self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.textField.autocapitalizationType = ([self.customFieldValue.customField shouldCapitalizeEveryWord]) ? UITextAutocapitalizationTypeWords : UITextAutocapitalizationTypeSentences;
        }
    }
}

#pragma mark - Data type
- (BOOL) isDateOrTimeType
{
    return ([self isDateType] || [self isTimeType]);
}

- (BOOL) isDateType
{
    return [self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeDate];

}

- (BOOL) isTimeType
{
    return [self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeTime];
}

- (NSUInteger) indexOfCurrentValue
{
    if ([self.customFieldValue.value length] == 0) {
        return NSNotFound;
    }
    
    NSString * currentValue = self.customFieldValue.value;
    
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        BOOL asBool = [currentValue boolValue];
        currentValue = asBool ? @"Yes" : @"No";
        return [[self booleanSelections] indexOfObject:currentValue];
    }
    
    if (self.customFieldValue.customField.options == nil) {
        return NSNotFound;
    }
    
    return [self.customFieldValue.customField.options indexOfObjectPassingTest:^BOOL(ZNGFieldOption * _Nonnull option, NSUInteger idx, BOOL * _Nonnull stop) {
        return [option.value isEqualToString:currentValue];
    }];
}

- (NSDateFormatter *) timeFormatter
{
    if (_timeFormatter == nil) {
        _timeFormatter = [[NSDateFormatter alloc] init];
        _timeFormatter.dateFormat = @"HH:mm:ss";
    }
    
    return _timeFormatter;
}

- (NSDate *) dateObjectForTimeString:(NSString *)string
{
    return [[self timeFormatter] dateFromString:string];
}

- (void) datePickerSelectedTime:(UIDatePicker *)sender
{
    NSDateFormatter * timeFormatter = [self timeFormatter];
    self.customFieldValue.value = [timeFormatter stringFromDate:datePicker.date];
}

- (void) datePickerSelectedDate:(UIDatePicker *)sender
{
    // Set our string to the UTC timestamp in seconds
    NSNumber * seconds = @((unsigned long long)[sender.date timeIntervalSince1970]);
    self.customFieldValue.value = [seconds stringValue];
    [self updateDisplay];
}

#pragma mark - Picker view
- (NSArray<NSString *> *) booleanSelections
{
    return @[@"", @"No", @"Yes"];
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString * value;
    
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        value = [self booleanSelections][row];
    } else {
        value = [self.customFieldValue.customField.options[row] value];
        self.customFieldValue.selectedCustomFieldOptionId = [self.customFieldValue.customField.options[row] optionId];
    }
    
    self.customFieldValue.value = value;
    [self updateDisplay];
}

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        return [[self booleanSelections] count];
    }
    
    return [self.customFieldValue.customField.options count];
}

- (NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        return [self booleanSelections][row];
    }
    
    if (row >= [self.customFieldValue.customField.options count]) {
        ZNGLogError(@"Out of bounds when retrieving single select custom field picker options.  %lld >= our total of %llu options", (long long)row, (unsigned long long)[self.customFieldValue.customField.options count]);
        return nil;
    }
    
    return [self.customFieldValue.customField.options[row] displayName];
}

#pragma mark - Text field delegate
- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Do not allow picking outside of the date/time pickers for those cases.  This is only relevant if the user has an external keyboard attached.
    if ([self isDateOrTimeType]) {
        return NO;
    }
    
    if (!numericOnly) {
        return YES;
    }
    
    NSCharacterSet * nonNumericCharacters = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSRange nonNumericRange = [string rangeOfCharacterFromSet:nonNumericCharacters];
    return (nonNumericRange.location == NSNotFound);    // Return YES if we did not find any non numeric characters
}

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
    // If this text field is not already first responder and the user hits clear, we do not want that itself to
    //  make the text field first responder.  This only occurs for date/time fields.
    if (justClearedDateOrTime) {
        justClearedDateOrTime = NO;
        return NO;
    }
    
    return YES;
}

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    // We will select the date picker's starting date when the user first begins editing.
    if ([self isTimeType]) {
        [self datePickerSelectedTime:datePicker];
    } else if ([self isDateType]) {
        [self datePickerSelectedDate:datePicker];
    }
}

- (BOOL) textFieldShouldClear:(UITextField *)textField
{
    if ([self isDateOrTimeType]) {
        justClearedDateOrTime = YES;
    }
    
    return YES;
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    UIView * picker = textField.inputView;
    BOOL pickerExists = (([picker isKindOfClass:[UIDatePicker class]]) || ([picker isKindOfClass:[UIPickerView class]]));
    
    // We only need to save our raw text if the picker view did not exist.  If a picker exists, changing the value of the picker will change our value.
    if (!pickerExists) {
        self.customFieldValue.value = textField.text;
    } else if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        self.customFieldValue.value = ([self.customFieldValue.value boolValue]) ? @"true" : @"false";
    }
}

- (void) applyChangesIfFirstResponder
{
    if (self.textField.isFirstResponder) {
        if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
            self.customFieldValue.value = ([self.customFieldValue.value boolValue]) ? @"true" : @"false";
        } else {
            self.customFieldValue.value = self.textField.text;
        }
    }
}

@end
