//
//  ZNGContactCustomFieldTableViewCell.h
//  Pods
//
//  Created by Ryan Farley on 3/17/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGContactFieldValue.h"

@interface ZNGContactCustomFieldTableViewCell : UITableViewCell

+ (UINib *)nib;

+ (NSString *)cellReuseIdentifier;

- (void)configureCellWithField:(ZNGContactField *)field andValues:(NSArray *)values;

@end
