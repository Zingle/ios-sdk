//
//  ZNGLabelCollectionViewCell.m
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import "ZNGLabelCollectionViewCell.h"
#import "UIColor+ZingleSDK.h"
#import "ZingleSDK/ZingleSDK-Swift.h"

@interface ZNGLabelCollectionViewCell ()

@property (weak, nonatomic) IBOutlet DashedBorderLabel *label;

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
    UIColor * color = label.backgroundUIColor;
    self.label.textColor = color;
    self.label.borderColor = color;
    self.label.backgroundColor = [color zng_colorByDarkeningColorWithValue:-0.5];
    [self.contentView setNeedsLayout];
}

@end
