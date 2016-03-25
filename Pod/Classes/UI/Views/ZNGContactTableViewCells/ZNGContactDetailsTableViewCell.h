//
//  ZNGContactDetailsTableViewCell.h
//  Pods
//
//  Created by Ryan Farley on 3/16/16.
//
//

#import <UIKit/UIKit.h>

@interface ZNGContactDetailsTableViewCell : UITableViewCell

+ (UINib *)nib;

+ (NSString *)cellReuseIdentifier;

- (void)configureCellWithField:(NSString *)field
               withPlaceholder:(NSString *)placeHolder
                 withIndexPath:(NSIndexPath *)indexPath
                  withDelegate:(id<UITextFieldDelegate>)delegate;

- (void)setTextFieldInputView:(UIView *)inputView;

@end