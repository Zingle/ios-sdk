//
//  ZNGContactCustomFieldTableViewCell.h
//  Pods
//
//  Created by Jason Neel on 8/23/16.
//
//

#import "ZNGContactEditTableViewCell.h"
@class JVFloatLabeledTextField;
@class ZNGContactFieldValue;

@interface ZNGContactCustomFieldTableViewCell : ZNGContactEditTableViewCell <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) IBOutlet JVFloatLabeledTextField * textField;

@property (nonatomic, strong) ZNGContactFieldValue * customFieldValue;

@end
