//
//  ZNGTableViewCell.h
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGContact.h"

@interface ZNGTableViewCell : UITableViewCell

+ (NSString *)cellReuseIdentifier;

+ (UINib *)nib;

- (void)configureCellWithContact:(ZNGContact *)contact;

@property (weak, nonatomic) IBOutlet UICollectionView *labelCollectionView;

@end
