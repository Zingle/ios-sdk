//
//  ZNGContactDetailsTableViewCell.m
//  Pods
//
//  Created by Ryan Farley on 3/16/16.
//
//

#import "ZNGContactDetailsTableViewCell.h"
#import "UIFont+OpenSans.h"

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
    self.textField.font = [UIFont openSansSemiboldFontOfSize:16.0f];
}

- (void)configureCellWithField:(NSString *)field withPlaceholder:(NSString *)placeHolder
{
    self.textField.placeholder = placeHolder;
    if (field.length > 0) {
        self.textField.text = field;
    }
}

@end
