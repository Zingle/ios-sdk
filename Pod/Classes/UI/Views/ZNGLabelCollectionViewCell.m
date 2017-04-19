//
//  ZNGLabelCollectionViewCell.m
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import "ZNGLabelCollectionViewCell.h"
#import "UIColor+ZingleSDK.h"
#import "ZNGDashedBorderLabel.h"

@interface ZNGLabelCollectionViewCell ()

@property (weak, nonatomic) IBOutlet ZNGDashedBorderLabel *label;

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
    NSString * paddedText = [NSString stringWithFormat:@" %@ ", [label.displayName uppercaseString]];
    self.label.text = paddedText;
    self.label.textColor = [label textUIColor];
    self.label.borderColor = [label textUIColor];
    self.label.backgroundColor = [label backgroundUIColor];
    [self.contentView setNeedsLayout];
}

@end
