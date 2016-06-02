//
//  ZNGLabelCollectionViewCell.h
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGLabel.h"

@interface ZNGLabelCollectionViewCell : UICollectionViewCell

+ (NSString *)cellReuseIdentifier;

+ (UINib *)nib;

- (void)configureCellWithLabel: (ZNGLabel *)label;
@end
