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
    NSDateFormatter * timeFormatter24Hour;
    NSDateFormatter * timeFormatter12HourAMPM;
    
    UIColor * defaultTextFieldBackgroundColor;
    
    BOOL numericOnly;
    BOOL justCleared;
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
    [self configureTimeOrDatePickerWithInitialValue];
    [self updateDisplay];
}

- (void) configureTimeOrDatePickerWithInitialValue
{
    if (![self isDateOrTimeType]) {
        return;
    }

    NSDate * date = nil;
    
    if ([self isTimeType]) {
        date = [self dateObjectForTimeString:self.customFieldValue.value];
    } else {
        double dateUTCDouble = [self.customFieldValue.value doubleValue];
        
        if (dateUTCDouble > 0.0) {
            date = [NSDate dateWithTimeIntervalSince1970:dateUTCDouble];
        }
    }
    
    if (date != nil) {
        datePicker.date = date;
    }
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
            self.textField.text = [self displayStringForDate:date];
        } else {
            self.textField.text = @"";
        }
    } else {
        
        NSString * value = self.customFieldValue.value;
        
        if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeTime]) {
            NSDate * date = [self dateObjectForTimeString:self.customFieldValue.value];
            value = [timeFormatter12HourAMPM stringFromDate:date];
        } else {
            NSUInteger index = [self indexOfCurrentValue];
            
            if (index != NSNotFound) {
                [pickerView selectRow:index inComponent:0 animated:NO];
            }
        }
        
        if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
            if ([self.customFieldValue.value length] == 0) {
                value = nil;
            } else {
                BOOL asBool = [self.customFieldValue.value boolValue];
                value = asBool ? @"Yes" : @"No";
            }
        }
        
        self.textField.text = value;
    }
}

- (void) configureInput
{
    BOOL optionsExist = [self.customFieldValue.customField.options count] > 0;
    
    // Do we need a picker?
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeTime]) {
        [self setupTimeFormatters];
        self.textField.clearButtonMode = UITextFieldViewModeAlways;
        datePicker = [[UIDatePicker alloc] init];
        datePicker.datePickerMode = UIDatePickerModeTime;
        datePicker.minuteInterval = 5;
        [datePicker addTarget:self action:@selector(datePickerSelectedTime:) forControlEvents:UIControlEventValueChanged];
        self.textField.inputView = datePicker;
        
        // Immediately changing a time picker's time zone causes the UIDatePicker to be disabled and unusable for Apple reasons.
        // This wonderfully intuitive and not at all scary delay prevents the UIDatePicker from committing seppuku.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            datePicker.timeZone = [NSTimeZone localTimeZone];
        });
    } else if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeDate]) {
        self.textField.clearButtonMode = UITextFieldViewModeAlways;
        datePicker = [[UIDatePicker alloc] init];
        datePicker.datePickerMode = UIDatePickerModeDate;
        datePicker.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        datePicker.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [datePicker addTarget:self action:@selector(datePickerSelectedDate:) forControlEvents:UIControlEventValueChanged];
        self.textField.inputView = datePicker;

    } else if ((optionsExist) || ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool])) {
        self.textField.clearButtonMode = UITextFieldViewModeAlways;
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

- (void) setupTimeFormatters
{
    if (timeFormatter24Hour == nil) {
        timeFormatter24Hour = [[NSDateFormatter alloc] init];
        timeFormatter24Hour.dateFormat = @"HH:mm";
    }
    
    if (timeFormatter12HourAMPM == nil) {
        timeFormatter12HourAMPM = [[NSDateFormatter alloc] init];
        timeFormatter12HourAMPM.dateStyle = NSDateFormatterNoStyle;
        timeFormatter12HourAMPM.timeStyle = NSDateFormatterShortStyle;
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

- (NSDate *) dateObjectForTimeString:(NSString *)string
{
    return [timeFormatter24Hour dateFromString:string];
}

- (void) datePickerSelectedTime:(UIDatePicker *)sender
{
    [self selectTime:datePicker.date];
}

- (void) selectTime:(NSDate *)time
{
    self.customFieldValue.value = [timeFormatter24Hour stringFromDate:time];
    [self updateDisplay];
}

- (void) datePickerSelectedDate:(UIDatePicker *)sender
{
    [self selectDate:datePicker.date];
}

- (void) selectDate:(NSDate *)date
{
    // Set our string to the UTC timestamp in seconds
    NSNumber * seconds = @((unsigned long long)[date timeIntervalSince1970]);
    self.customFieldValue.value = [seconds stringValue];
    [self updateDisplay];
}

#pragma mark - Picker view
- (NSArray<NSString *> *) booleanSelections
{
    return @[@"No", @"Yes"];
}

// When the user starts editing a bool custom field with no existing value, what should we show before they move the picker?
- (NSString *) initialBooleanSelection
{
    return @"Yes";
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
    if (justCleared) {
        justCleared = NO;
        return NO;
    }
    
    return YES;
}

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    BOOL inputViewIsPicker = ([self.textField.inputView isKindOfClass:[UIPickerView class]]);
    BOOL inputViewIsDatePicker = ([self.textField.inputView isKindOfClass:[UIDatePicker class]]);
    
    if ((inputViewIsPicker) || (inputViewIsDatePicker)) {
        // This is a picker type field.  If no value is selected, we will select the first value.
        if ([self.customFieldValue.value length] == 0) {
            [self selectInitialValue];
        }

        if (inputViewIsDatePicker) {
            [self repairStupidBrokenDatePicker:(UIDatePicker *)self.textField.inputView];
        }
    }
}

// There is some Apple-style wackiness going on in iOS 11 where time UIDatePickers become disabled and unusable
//  if their date value is changed or the time zone changed in certain circumstances.  Flopping the date picker
//  mode back and forth resolves this, though it also blows away the minuteInterval property.
// The life of an iOS developer is one of shame and terror.
- (void) repairStupidBrokenDatePicker:(UIDatePicker *)datePicker
{
    if (datePicker.datePickerMode == UIDatePickerModeTime) {
        // As an extra nugget of happiness and sanity, removing this 0 second delay causes the date picker to freeze
        //  itself, but only when a date (not time) field is immediately above the time field, and the IQKeyboardManager-Swift
        //  down arrow is used to access this time field.  It does not happen upward, only downward, and does not happen
        //  for custom fields of any other type.
        // Delaying this magical date picker mode toggle to the next run loop cycle fixes this.
        // I think I need a shower.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSInteger interval = datePicker.minuteInterval;
            datePicker.datePickerMode = UIDatePickerModeDate;
            datePicker.datePickerMode = UIDatePickerModeTime;
            datePicker.minuteInterval = interval;
        });
    }
}

- (void) selectInitialValue
{
    if ([self isTimeType]) {
        [self selectInitialTime];
    } else if ([self isDateType]) {
        [self selectInitialDate];
    } else {
        [self selectInitialPickerValue];
    }
}

- (void) selectInitialTime
{
    NSDate * date = [NSDate date];
    [self selectTime:date];
}

- (void) selectInitialDate
{
    NSDate * date = [NSDate date];
    [self selectDate:date];
}

- (void) selectInitialPickerValue
{
    NSString * initialValue;
    
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        initialValue = [self initialBooleanSelection];
    } else {
        initialValue = [[self.customFieldValue.customField.options firstObject] value];
    }
    
    self.customFieldValue.value = initialValue;
    [self updateDisplay];
}

- (BOOL) textFieldShouldClear:(UITextField *)textField
{
    justCleared = YES;
    self.customFieldValue.value = nil;

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
        // Any picker type custom field will save its own value every time a value is selected in the picker.
        // Booleans will need to be sanitized to "true" or "false" from other truthy values (yes/no)
        if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
            self.customFieldValue.value = ([self.customFieldValue.value boolValue]) ? @"true" : @"false";
        } else {
            // Non-picker, non-bool fields will need to be saved if they are mid-edit.
            UIView * picker = self.textField.inputView;
            BOOL pickerExists = (([picker isKindOfClass:[UIDatePicker class]]) || ([picker isKindOfClass:[UIPickerView class]]));
            
            if (!pickerExists) {
                self.customFieldValue.value = self.textField.text;
            }
        }
    }
}

@end
