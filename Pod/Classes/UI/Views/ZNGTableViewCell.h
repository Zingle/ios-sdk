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
@class ZNGLabelGridView;

@interface ZNGTableViewCell : MGSwipeTableCell

+ (NSString *)cellReuseIdentifier;

+ (UINib *)nib;

- (void)configureCellWithContact:(ZNGContact *)contact withServiceId:(NSString *)serviceId;

@property (nonatomic, weak) IBOutlet ZNGLabelGridView * labelGrid;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIView * closedShadingOverlay;


@end
