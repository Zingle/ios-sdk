//
//  ZNGContactDateOrTimeFieldTableViewCell.m
//  ZingleSDK
//
//  Created by Jason Neel on 11/23/20.
//

#import "ZNGContactDateOrTimeFieldTableViewCell.h"
#import "ZNGContactFieldValue.h"
#import "ZNGContactDateOrTimeInputManager.h"

@import JVFloatLabeledTextField;
@import SBObjectiveCWrapper;

@implementation ZNGContactDateOrTimeFieldTableViewCell
{
    UIDatePicker * datePicker;
    ZNGContactDateOrTimeInputManager * inputManager;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    datePicker = [[UIDatePicker alloc] init];
    datePicker.minuteInterval = 5;
    [datePicker addTarget:self action:@selector(userSelectedDateOrTime:) forControlEvents:UIControlEventValueChanged];
    
    if (@available(iOS 13.4, *)) {
        datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    
    self.textField.inputView = datePicker;
}

// Override shouldChangeCharacters to disallow any edits outside of the date picker
- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return NO;
}

- (void) configureInput
{
    [super configureInput];
    
    NSString * oldFieldId = inputManager.contactFieldValue.customField.contactFieldId;
    NSString * fieldId = self.customFieldValue.customField.contactFieldId;
    
    if (![fieldId isEqualToString:oldFieldId]) {
        inputManager = [[ZNGContactDateOrTimeInputManager alloc] initWithContactFieldValue:self.customFieldValue];
    }
    
    NSString * type = self.customFieldValue.customField.dataType;
    
    // Note that both dates and anniversaries use UTC time zone due to the bizarre
    //  decision to represent dates as epoch timestamps in the contact field API.
    
    if ([type isEqualToString:ZNGContactFieldDataTypeDate]) {
        datePicker.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        datePicker.datePickerMode = UIDatePickerModeDate;
    } else if ([type isEqualToString:ZNGContactFieldDataTypeAnniversary]) {
        datePicker.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        datePicker.datePickerMode = UIDatePickerModeDate;
    } else if ([type isEqualToString:ZNGContactFieldDataTypeTime]) {
        datePicker.datePickerMode = UIDatePickerModeTime;
        datePicker.timeZone = [NSTimeZone localTimeZone];
    } else if ([type isEqualToString:ZNGContactFieldDataTypeDateTime]) {
        datePicker.datePickerMode = UIDatePickerModeDateAndTime;
        datePicker.timeZone = [NSTimeZone localTimeZone];
    } else {
        SBLogWarning(@"Unrecognized date or time data type: %@", type);
    }
    
    [self updateDisplay];
}

- (void) updateDisplay
{
    [super updateDisplay];
    
    self.textField.text = [inputManager displayValue];
    datePicker.date = [inputManager valueAsDate];
    
    [self repairStupidBrokenDatePicker:datePicker];
}

- (void) applyInProgressChanges
{
    // Override super behavior (that applies the text field value) with a no-op since we are
    //  manually handling the value via UIDatePicker methods.
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    // Override super behavior (that applies the text field value) with a no-op since we are
    //  manually handling the value via UIDatePicker methods.
}

- (void) userSelectedDateOrTime:(UIDatePicker *)picker
{
    [inputManager userSelectedDate:picker.date];
    [self updateDisplay];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self repairStupidBrokenDatePicker:datePicker];
}

// There is some Apple-style wackiness going on in iOS 11 where time UIDatePickers become disabled and unusable
//  if their date value is changed or the time zone changed in certain circumstances.  Flopping the date picker
//  mode back and forth resolves this, though it also blows away the minuteInterval property.
// The life of an iOS developer is one of shame and terror.
//
// As an extra nugget of happiness and sanity, removing this 0 second delay causes the date picker to freeze
//  itself, but only when a date (not time) field is immediately above the time field, and the IQKeyboardManager-Swift
//  down arrow is used to access this time field.  It does not happen upward, only downward, and does not happen
//  for custom fields of any other type.
// Delaying this magical date picker mode toggle to the next run loop cycle fixes this.
// I think I need a shower.
- (void) repairStupidBrokenDatePicker:(UIDatePicker *)datePicker
{
    UIDatePickerMode mode = datePicker.datePickerMode;
    UIDatePickerMode otherMode = (mode == UIDatePickerModeDate) ? UIDatePickerModeTime : UIDatePickerModeDate;
    
    dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue(), ^{
        NSInteger interval = datePicker.minuteInterval;
        datePicker.datePickerMode = otherMode;
        datePicker.datePickerMode = mode;
        datePicker.minuteInterval = interval;
    });
}

@end
