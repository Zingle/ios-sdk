//
//  ZNGContactLabelsTableViewCell.h
//  Pods
//
//  Created by Ryan Farley on 3/16/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGLabel.h"

@interface ZNGContactLabelsTableViewCell : UITableViewCell

+ (UINib *)nib;

+ (NSString *)cellReuseIdentifier;

- (void)configureDeleteContactLabel;

- (void)configureAddMoreLabel;

- (void)configureCellWithLabel:(ZNGLabel *)label;

@end
