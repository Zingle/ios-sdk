//
//  ZNGContactTextFieldTableViewCell.m
//  
//
//  Created by Jason Neel on 11/23/20.
//

#import "ZNGContactTextFieldTableViewCell.h"
#import "ZNGContactFieldValue.h"

@import JVFloatLabeledTextField;

@implementation ZNGContactTextFieldTableViewCell
{
    BOOL justCleared;
}

- (void) prepareForReuse
{
    [super prepareForReuse];
    self.textField.text = nil;
}

- (void) configureInput
{
    [super configureInput];
    
    self.textField.placeholder = self.customFieldValue.customField.displayName;
    self.textField.enabled = !self.editingLocked;
    self.textField.clearButtonMode = UITextFieldViewModeNever;
    
    if ([self numericOnly]) {
        self.textField.keyboardType = UIKeyboardTypeNumberPad;
    } else {
        self.textField.keyboardType = UIKeyboardTypeDefault;
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = ([self.customFieldValue.customField shouldCapitalizeEveryWord]) ? UITextAutocapitalizationTypeWords : UITextAutocapitalizationTypeSentences;
    }
}

- (void) applyInProgressChanges
{
    self.customFieldValue.value = self.textField.text;
}

- (BOOL) numericOnly
{
    return [self.customFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeNumber];
}

#pragma mark - UITextField Delegate
- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (![self numericOnly]) {
        return YES;
    }
    
    NSCharacterSet * nonNumericCharacters = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSRange nonNumericRange = [string rangeOfCharacterFromSet:nonNumericCharacters];
    return (nonNumericRange.location == NSNotFound);    // Return YES if we did not find any non numeric characters
}

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
    // If this text field is not already first responder and the user hits clear, we do not want that itself to
    //  make the text field first responder.
    if (justCleared) {
        justCleared = NO;
        return NO;
    }
    
    return YES;
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    self.customFieldValue.value = textField.text;
}

- (BOOL) textFieldShouldClear:(UITextField *)textField
{
    justCleared = YES;
    self.customFieldValue.value = nil;
    
    return YES;
}

@end
