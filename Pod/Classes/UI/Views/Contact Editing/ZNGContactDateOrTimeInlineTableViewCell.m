//
//  ZNGContactDateOrTimeInlineTableViewCell.m
//  ZingleSDK
//
//  Created by Jason Neel on 12/10/20.
//

#import "ZNGContactDateOrTimeInlineTableViewCell.h"
#import "ZNGContactDateOrTimeInputManager.h"
#import "ZNGContactFieldValue.h"

static const CGFloat noValueAlpha = 0.33;

@import SBObjectiveCWrapper;

@implementation ZNGContactDateOrTimeInlineTableViewCell
{
    ZNGContactDateOrTimeInputManager * inputManager;
}

- (void) configureInput
{
    [super configureInput];
    
    NSString * oldFieldId = inputManager.contactFieldValue.customField.contactFieldId;
    NSString * fieldId = self.customFieldValue.customField.contactFieldId;
    
    if (![fieldId isEqualToString:oldFieldId]) {
        inputManager = [[ZNGContactDateOrTimeInputManager alloc] initWithContactFieldValue:self.customFieldValue];
        self.fieldNameLabel.text = self.customFieldValue.customField.displayName;
    }
    
    NSString * type = self.customFieldValue.customField.dataType;
    
    // Note that both dates and anniversaries use UTC time zone due to the bizarre
    //  decision to represent dates as epoch timestamps in the contact field API.
    
    if ([type isEqualToString:ZNGContactFieldDataTypeDate]) {
        self.datePicker.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        self.datePicker.datePickerMode = UIDatePickerModeDate;
    } else if ([type isEqualToString:ZNGContactFieldDataTypeAnniversary]) {
        self.datePicker.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        self.datePicker.datePickerMode = UIDatePickerModeDate;
    } else if ([type isEqualToString:ZNGContactFieldDataTypeTime]) {
        self.datePicker.datePickerMode = UIDatePickerModeTime;
        self.datePicker.timeZone = [NSTimeZone localTimeZone];
    } else if ([type isEqualToString:ZNGContactFieldDataTypeDateTime]) {
        self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
        self.datePicker.timeZone = [NSTimeZone localTimeZone];
    } else {
        SBLogWarning(@"Unrecognized date or time data type: %@", type);
    }
    
    [self updateDisplay];
}

- (void) updateDisplay
{
    [super updateDisplay];
    
    NSDate * date = inputManager.valueAsDate;
    self.datePicker.date = date;
    self.datePicker.alpha = (date != nil) ? 1.0 : noValueAlpha;
    self.clearButton.hidden = (date == nil);
}

- (void) applyInProgressChanges
{
    
}

- (IBAction) userSelectedDate:(UIDatePicker *)datePicker
{
    [inputManager userSelectedDate:datePicker.date];
    [self updateDisplay];
}

- (IBAction) userPressedClear:(UIButton *)clearButton
{
    [inputManager userSelectedDate:nil];
    [self updateDisplay];
}

@end
