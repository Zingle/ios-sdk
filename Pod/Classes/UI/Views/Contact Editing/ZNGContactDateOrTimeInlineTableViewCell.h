//
//  ZNGContactDateOrTimeInlineTableViewCell.h
//  ZingleSDK
//
//  Created by Jason Neel on 12/10/20.
//

#import "ZNGContactCustomFieldTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZNGContactDateOrTimeInlineTableViewCell : ZNGContactCustomFieldTableViewCell

@property (weak, nonatomic, nullable) IBOutlet UIDatePicker * datePicker;
@property (weak, nonatomic, nullable) IBOutlet UILabel * fieldNameLabel;
@property (weak, nonatomic, nullable) IBOutlet UIButton * clearButton;

- (IBAction) userSelectedDate:(UIDatePicker *)datePicker;
- (IBAction) userPressedClear:(UIButton *)clearButton;

@end

NS_ASSUME_NONNULL_END
