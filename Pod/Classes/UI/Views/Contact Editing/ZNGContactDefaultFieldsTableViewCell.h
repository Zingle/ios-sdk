//
//  ZNGContactDefaultFieldsTableViewCell.h
//  Pods
//
//  Created by Jason Neel on 4/26/17.
//
//

#import "ZNGContactEditTableViewCell.h"

@class JVFloatLabeledTextField;
@class ZNGContact;
@class ZNGContactFieldValue;

@interface ZNGContactDefaultFieldsTableViewCell : ZNGContactEditTableViewCell <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong, nullable) IBOutlet UIImageView * avatarImageView;
@property (nonatomic, strong, nullable) IBOutlet JVFloatLabeledTextField * titleField;
@property (nonatomic, strong, nullable) IBOutlet JVFloatLabeledTextField * firstNameField;
@property (nonatomic, strong, nullable) IBOutlet JVFloatLabeledTextField * lastNameField;

/**
 *  A contact reference, used only to populate the avatar.  This object will not be modified.
 */
@property (nonatomic, strong, nullable) ZNGContact * contact;

@property (nonatomic, strong, nullable) ZNGContactFieldValue * titleFieldValue;
@property (nonatomic, strong, nullable) ZNGContactFieldValue * firstNameFieldValue;
@property (nonatomic, strong, nullable) ZNGContactFieldValue * lastNameFieldValue;

@end
