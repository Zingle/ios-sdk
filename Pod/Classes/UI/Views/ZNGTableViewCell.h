//
//  ZNGTableViewCell.h
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGContact.h"
@import MGSwipeTableCell;

@class ZNGTableViewCell;
@class LabelGridView;

@interface ZNGTableViewCell : MGSwipeTableCell

+ (NSString *)cellReuseIdentifier;

+ (UINib *)nib;

- (void)configureCellWithContact:(ZNGContact *)contact withServiceId:(NSString *)serviceId;

@property (nonatomic, weak) IBOutlet LabelGridView * labelGrid;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;


@end
