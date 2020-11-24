//
//  ZNGContactTextFieldTableViewCell.h
//  
//
//  Created by Jason Neel on 11/23/20.
//

#import "ZNGContactCustomFieldTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZNGContactTextFieldTableViewCell : ZNGContactCustomFieldTableViewCell <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet JVFloatLabeledTextField * textField;

@end

NS_ASSUME_NONNULL_END
