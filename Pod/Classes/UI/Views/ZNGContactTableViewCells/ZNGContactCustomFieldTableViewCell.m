//
//  ZNGContactCustomFieldTableViewCell.m
//  Pods
//
//  Created by Ryan Farley on 3/17/16.
//
//

#import "ZNGContactCustomFieldTableViewCell.h"
#import "UIColor+ZingleSDK.h"
#import "UIFont+OpenSans.h"

@interface ZNGContactCustomFieldTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation ZNGContactCustomFieldTableViewCell

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
    self.label.font = [UIFont openSansSemiboldFontOfSize:16.0f];
    self.textField.font = [UIFont openSansSemiboldFontOfSize:16.0f];
    self.label.textColor = [UIColor colorFromHexString:@"#155C8C"];
    self.textField.textColor = [UIColor colorFromHexString:@"#00a1df"];
}

- (void)configureCellWithField:(ZNGContactField *)field
                    withValues:(NSArray *)values
                 withIndexPath:(NSIndexPath *)indexPath
                  withDelegate:(id<UITextFieldDelegate>)delegate
{
    self.label.text = field.displayName;
    self.textField.placeholder = field.displayName;
    self.textField.superview.tag = indexPath.section;
    self.textField.tag = indexPath.row;
    self.textField.delegate = delegate;
    
    for (ZNGContactFieldValue *value in values) {
        if ([value.customField.contactFieldId isEqualToString:field.contactFieldId]) {
            self.textField.text = value.value;
        }
    }
}

@end
