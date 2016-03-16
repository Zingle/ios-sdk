//
//  ZNGLabelCollectionViewCell.m
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import "ZNGLabelCollectionViewCell.h"
#import "UIFont+OpenSans.h"

@interface ZNGLabelCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ZNGLabelCollectionViewCell

+ (NSString *)cellReuseIdentifier
{
    return NSStringFromClass([self class]);
}

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
}

- (void)configureCellWithLabel: (ZNGLabel *)label
{
    self.backgroundColor = [label backgroundUIColor];
    self.label.textColor = [label textUIColor];
    self.label.text = [label.displayName uppercaseString];
    self.label.font = [UIFont openSansSemiboldFontOfSize:11.0f];
    self.layer.cornerRadius = 3;
    self.clipsToBounds = YES;
}

@end
