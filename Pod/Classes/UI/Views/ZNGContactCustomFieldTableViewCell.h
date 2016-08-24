//
//  ZNGContactCustomFieldTableViewCell.h
//  Pods
//
//  Created by Jason Neel on 8/23/16.
//
//

#import <UIKit/UIKit.h>
@class JVFloatLabeledTextField;
@class ZNGContactFieldValue;

@interface ZNGContactCustomFieldTableViewCell : UITableViewCell <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet JVFloatLabeledTextField * textField;

@property (nonatomic, copy) ZNGContactFieldValue * customFieldValue;

@end
