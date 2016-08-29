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

@import JVFloatLabeledTextField;

static const int zngLogLevel = ZNGLogLevelVerbose;

@implementation ZNGContactCustomFieldTableViewCell
{
    UIPickerView * pickerView;
    UIDatePicker * datePicker;
    
    NSDateFormatter * dateFormatter;
    NSDateFormatter * _timeFormatter;
    
    BOOL numericOnly;
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
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    
    return [dateFormatter stringFromDate:date];
}

- (void) setCustomFieldValue:(ZNGContactFieldValue *)customFieldValue
{
    ZNGLogVerbose(@"%@ custom field type set to %@ (type %@), was %@", [self class], customFieldValue.customField.displayName, customFieldValue.customField.dataType, _customFieldValue.customField.displayName);
    
    _customFieldValue = customFieldValue;
    self.textField.placeholder = customFieldValue.customField.displayName;
    
    [self configureInput];
    [self updateDisplay];
}

- (void) updateDisplay
{
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
        
        self.textField.text = self.customFieldValue.value;
    }
}

- (void) configureInput
{
    // Temporary debugging code
//    if ([self.customFieldValue.customField.displayName isEqualToString:@"Title"]) {
//        NSLog(@"Break");
//        self.customFieldValue.customField.dataType = ZNGContactFieldDataTypeSingleSelect;
//    }
    
    // Do we need a picker?
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeTime]) {
        datePicker = [[UIDatePicker alloc] init];
        datePicker.datePickerMode = UIDatePickerModeTime;
        [datePicker addTarget:self action:@selector(daetPickerSelectedTime:) forControlEvents:UIControlEventValueChanged];
        self.textField.inputView = datePicker;
    } else if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeDate]) {
        datePicker = [[UIDatePicker alloc] init];
        datePicker.datePickerMode = UIDatePickerModeDate;
        [datePicker addTarget:self action:@selector(datePickerSelectedDate:) forControlEvents:UIControlEventValueChanged];
        self.textField.inputView = datePicker;

    } else if (([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeSingleSelect]) || ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool])) {
        pickerView = [[UIPickerView alloc] init];
        pickerView.delegate = self;
        pickerView.dataSource = self;
        self.textField.inputView = pickerView;
    } else {
        // This is text input
        // Is it numeric of text?
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

- (NSUInteger) indexOfCurrentValue
{
    if ([self.customFieldValue.value length] == 0) {
        return NSNotFound;
    }
    
    NSString * currentValue = self.customFieldValue.value;
    
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        return [[self booleanSelections] indexOfObject:currentValue];
    }
    
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeSingleSelect]) {
        return [self.customFieldValue.customField.options indexOfObjectPassingTest:^BOOL(ZNGFieldOption * _Nonnull option, NSUInteger idx, BOOL * _Nonnull stop) {
            return [option.value isEqualToString:currentValue];
        }];
    }
    
    return NSNotFound;
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
    // The user has selected a year.  We will use date components to find the UTC time at noon on that day.
    NSCalendar * calendar = [NSCalendar currentCalendar];
    NSDateComponents * components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:datePicker.date];
    components.hour = 12;
    NSDate * noonThatDay = [calendar dateFromComponents:components];
    
    // Set our string to the UTC timestamp in seconds
    NSNumber * seconds = @((unsigned long long)[noonThatDay timeIntervalSince1970]);
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
    if (!numericOnly) {
        return YES;
    }
    
    NSCharacterSet * nonNumericCharacters = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSRange nonNumericRange = [string rangeOfCharacterFromSet:nonNumericCharacters];
    return (nonNumericRange.location == NSNotFound);    // Return YES if we did not find any non numeric characters
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    self.customFieldValue.value = textField.text;
}

@end
