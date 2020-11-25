//
//  ZNGContactDateOrTimeFieldTableViewCell.m
//  ZingleSDK
//
//  Created by Jason Neel on 11/23/20.
//

#import "ZNGContactDateOrTimeFieldTableViewCell.h"
#import "ZNGContactFieldValue.h"

@import JVFloatLabeledTextField;
@import SBObjectiveCWrapper;

@implementation ZNGContactDateOrTimeFieldTableViewCell
{
    UIDatePicker * datePicker;
    
    NSDateFormatter * timeFormatter24Hour;
    NSDateFormatter * timeFormatterReadable;
    
    // The date formatter for both dates and datetime.
    // Note that `dateStyle` and `timeZone` will differ depending on field type (date vs. datetime).
    NSDateFormatter * dateFormatter;
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
    
    timeFormatter24Hour = [[NSDateFormatter alloc] init];
    timeFormatter24Hour.dateFormat = @"HH:mm";
    
    timeFormatterReadable = [[NSDateFormatter alloc] init];
    timeFormatterReadable.dateStyle = NSDateFormatterNoStyle;
    timeFormatterReadable.timeStyle = NSDateFormatterShortStyle;
    
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterLongStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
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
    
    NSString * type = self.customFieldValue.customField.dataType;
    
    // Note that both dates and anniversaries use UTC time zone due to the bizarre
    //  decision to represent dates as epoch timestamps in the contact field API.
    
    if ([type isEqualToString:ZNGContactFieldDataTypeDate]) {
        dateFormatter.dateStyle = NSDateFormatterLongStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        datePicker.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        datePicker.datePickerMode = UIDatePickerModeDate;
    } else if ([type isEqualToString:ZNGContactFieldDataTypeAnniversary]) {
        dateFormatter.dateStyle = NSDateFormatterLongStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        datePicker.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        datePicker.datePickerMode = UIDatePickerModeDate;
    } else if ([type isEqualToString:ZNGContactFieldDataTypeTime]) {
        datePicker.datePickerMode = UIDatePickerModeTime;
        datePicker.timeZone = [NSTimeZone localTimeZone];
    } else if ([type isEqualToString:ZNGContactFieldDataTypeDateTime]) {
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        dateFormatter.timeZone = [NSTimeZone localTimeZone];
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
    
    if ([self.customFieldValue.value length] > 0) {
        NSString * type = self.customFieldValue.customField.dataType;
        
        if ([type isEqualToString:ZNGContactFieldDataTypeTime]) {
            NSDate * date = [timeFormatter24Hour dateFromString:self.customFieldValue.value];
            NSString * displayText = (date != nil) ? [timeFormatterReadable stringFromDate:date] : nil;
            self.textField.text = displayText;
        } else {
            // Do a formatting sanity check to keep styling consistent, if possible.
            NSDate * date = [self ambitiouslyInterpretedDate];
            
            if (date != nil) {
                self.textField.text = [dateFormatter stringFromDate:date];
            } else {
                // Sanity check failed. Just spew whatever the server gave us into the text field.
                self.textField.text = self.customFieldValue.value;
            }
        }
    } else {
        // Start the date picker at today/now for convenience.
        datePicker.date = [NSDate date];
        self.textField.text = nil;
    }
    
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

// Try multiple methods of parsing the current value as a date
- (NSDate *) ambitiouslyInterpretedDate
{
    NSDate * date = [dateFormatter dateFromString:self.customFieldValue.value];
    
    if (date == nil) {
        date = [timeFormatter24Hour dateFromString:self.customFieldValue.value];
    }
    
    if (date == nil) {
        long long epochNumber = [self.customFieldValue.value longLongValue];
        
        if (epochNumber > 0) {
            date = [NSDate dateWithTimeIntervalSince1970:epochNumber];
        }
    }
    
    return date;
}

- (void) userSelectedDateOrTime:(UIDatePicker *)picker
{
    NSDate * date = picker.date;
    self.customFieldValue.value = [self valueToSetForSelectedDate:date];
    [self updateDisplay];
}

- (NSString *) valueToSetForSelectedDate:(NSDate *)date
{
    if (date == nil) {
        SBLogWarning(@"Date picker seems to have selected a nil date. Strange.");
        return nil;
    }
    
    NSString * type = self.customFieldValue.customField.dataType;
    
    if (([type isEqualToString:ZNGContactFieldDataTypeDate])
        || ([type isEqualToString:ZNGContactFieldDataTypeDateTime])
        || ([type isEqualToString:ZNGContactFieldDataTypeAnniversary])) {
        
        // Return epoch seconds in string form
        return [@((NSUInteger)[date timeIntervalSince1970]) stringValue];
    }
    
    // else we are a time
    return [timeFormatter24Hour stringFromDate:date];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self repairStupidBrokenDatePicker:datePicker];
    [self userSelectedDateOrTime:datePicker];
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
