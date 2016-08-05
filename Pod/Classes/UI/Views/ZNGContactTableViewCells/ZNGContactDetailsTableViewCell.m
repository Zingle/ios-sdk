//
//  ZNGContactDetailsTableViewCell.m
//  Pods
//
//  Created by Ryan Farley on 3/16/16.
//
//

#import "ZNGContactDetailsTableViewCell.h"

@interface ZNGContactDetailsTableViewCell ()

@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation ZNGContactDetailsTableViewCell

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
}

+ (NSString *)cellReuseIdentifier
{
    return NSStringFromClass([self class]);
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)configureCellWithField:(NSString *)field
               withPlaceholder:(NSString *)placeHolder
                 withIndexPath:(NSIndexPath *)indexPath
                  withDelegate:(id<UITextFieldDelegate>)delegate
{
    self.textField.placeholder = placeHolder;
    if (field.length > 0) {
        self.textField.text = field;
    } else {
        self.textField.text = @"";
    }
    self.superview.tag = indexPath.section;
    self.textField.tag = indexPath.row;
    self.textField.delegate = delegate;
}

- (void)setTextFieldInputView:(UIView *)inputView
{
    self.textField.inputView = inputView;
}

@end
