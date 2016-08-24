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

- (void) setCustomFieldValue:(ZNGContactFieldValue *)customFieldValue
{
    ZNGLogVerbose(@"%@ custom field type set to %@, was %@", [self class], customFieldValue.customField.displayName, _customFieldValue.customField.displayName);
    
    _customFieldValue = customFieldValue;
    
    self.textField.placeholder = customFieldValue.customField.displayName;
    self.textField.text = customFieldValue.value;
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    self.customFieldValue.value = textField.text;
}

@end
