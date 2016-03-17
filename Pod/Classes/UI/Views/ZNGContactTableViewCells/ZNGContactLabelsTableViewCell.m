//
//  ZNGContactLabelsTableViewCell.m
//  Pods
//
//  Created by Ryan Farley on 3/16/16.
//
//

#import "ZNGContactLabelsTableViewCell.h"
#import "UIColor+ZingleSDK.h"
#import "UIFont+OpenSans.h"

@interface ZNGContactLabelsTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ZNGContactLabelsTableViewCell

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
}

- (void)configureDeleteContactLabel
{
    self.label.text = @"DELETE CONTACT";
    self.label.textColor = [UIColor whiteColor];
    self.backgroundColor = [UIColor redColor];
}

- (void)configureAddMoreLabel
{
    self.label.text = @"+ ADD LABEL";
    self.label.textColor = [UIColor grayColor];
    self.backgroundColor = [UIColor lightGrayColor];
}

- (void)configureCellWithLabel:(ZNGLabel *)label;
{
    self.label.text = [label.displayName uppercaseString];
    self.label.textColor = [UIColor colorFromHexString:label.textColor];
    self.backgroundColor = [UIColor colorFromHexString:label.backgroundColor];
}
@end
