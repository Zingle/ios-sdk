//
//  ZNGContactSingleSelectFieldTableViewCell.m
//  ZingleSDK
//
//  Created by Jason Neel on 11/23/20.
//

#import "ZNGContactSingleSelectFieldTableViewCell.h"
#import "ZNGContactFieldValue.h"
#import "ZNGFieldOption.h"

@import JVFloatLabeledTextField;
@import SBObjectiveCWrapper;

@implementation ZNGContactSingleSelectFieldTableViewCell
{
    UIPickerView * pickerView;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    pickerView = [[UIPickerView alloc] init];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    self.textField.inputView = pickerView;
    self.textField.clearButtonMode = UITextFieldViewModeAlways;

}

- (void) updateDisplay
{
    [super updateDisplay];
    
    NSUInteger index = [self indexOfCurrentValue];
    
    if (index != NSNotFound) {
        [pickerView selectRow:index inComponent:0 animated:NO];
    }
}

- (void) configureInput
{
    [super configureInput];
    
    [pickerView reloadAllComponents];
}

- (void) applyInProgressChanges
{
    // We only need to handle bools. Other cases set values automatically when UIPickerView values change.
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        self.customFieldValue.value = ([self.customFieldValue.value boolValue]) ? @"true" : @"false";
    }
}

#pragma mark - Text field delegate
- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    if ([self.customFieldValue.value length] == 0) {
        NSUInteger selectionIndex = [self indexOfCurrentValue];
        
        if (selectionIndex != NSNotFound) {
            [pickerView selectRow:selectionIndex inComponent:0 animated:NO];
        }
    }
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        self.customFieldValue.value = ([self.customFieldValue.value boolValue]) ? @"true" : @"false";
    }
}

#pragma mark - UIPickerView handling
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
        SBLogError(@"Out of bounds when retrieving single select custom field picker options.  %lld >= our total of %llu options", (long long)row, (unsigned long long)[self.customFieldValue.customField.options count]);
        return nil;
    }
    
    return [self.customFieldValue.customField.options[row] displayName];
}

@end
