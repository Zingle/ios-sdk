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

    if (index == NSNotFound) {
        self.textField.text = nil;
        [pickerView selectRow:0 inComponent:0 animated:NO];
        return;
    }
    
    NSArray <NSString *> * options = [self availableDisplayNames];
    
    if (index >= [options count]) {
        SBLogWarning(@"Out of bounds showing selection #(%d) from %d available options for %@", (int)index, (int)[options count], self.customFieldValue.customField.displayName);
        return;
    }
    
    [pickerView selectRow:index inComponent:0 animated:NO];
    self.textField.text = options[index];
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
        if ([self.customFieldValue.value length] > 0) {
            self.customFieldValue.value = ([self.customFieldValue.value boolValue]) ? @"true" : @"false";
        }
    }
}

#pragma mark - Text field delegate
- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    if ([[self availableDisplayNames] count] == 0) {
        return;
    }
    
    NSUInteger initialIndex = 0;
    
    if ([self.customFieldValue.value length] > 0) {
        NSUInteger currentIndex = [self indexOfCurrentValue];
        
        if (currentIndex != NSNotFound) {
            initialIndex = currentIndex;
        }
    }
    
    [pickerView selectRow:initialIndex inComponent:0 animated:NO];
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        self.customFieldValue.value = ([self.customFieldValue.value boolValue]) ? @"true" : @"false";
    }
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Disallow manual typing since we have enumerated options
    return NO;
}

#pragma mark - UIPickerView handling
- (NSArray <NSString *> *) availableDisplayNames
{
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        return [self booleanSelections];
    }
    
    NSArray <ZNGFieldOption *> * options = self.customFieldValue.customField.options;
    
    if ([options count] == 0) {
        return @[];
    }
    
    NSMutableArray <NSString *> * optionNames = [[NSMutableArray alloc] initWithCapacity:[options count]];
    
    [options enumerateObjectsUsingBlock:^(ZNGFieldOption * _Nonnull option, NSUInteger i, BOOL * _Nonnull stop) {
        [optionNames addObject:option.displayName ?: @""];
    }];
    
    return optionNames;
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

- (NSArray<NSString *> *) booleanSelections
{
    return @[@"No", @"Yes"];
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSArray <NSString *> * optionNames = [self availableDisplayNames];
    
    if (row >= [optionNames count]) {
        self.customFieldValue.value = nil;
        [self updateDisplay];
        return;
    }
    
    NSString * value;
    
    if ([self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        value = ([optionNames[row] boolValue]) ? @"true" : @"false";
    } else {
        ZNGFieldOption * option = self.customFieldValue.customField.options[row];
        self.customFieldValue.selectedCustomFieldOptionId = option.optionId;
        value = option.value;
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
    return [[self availableDisplayNames] count];
}

- (NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSArray <NSString *> * options = [self availableDisplayNames];
    
    if (row >= [options count]) {
        SBLogError(@"Out of bounds when retrieving single select custom field picker options.  %lld >= our total of %llu options", (long long)row, (unsigned long long)[options count]);
        return nil;
    }
    
    return options[row];
}

@end
