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

@class ZNGLabelGridView;

@interface ZNGTableViewCell : MGSwipeTableCell

+ (NSString *)cellReuseIdentifier;

+ (UINib *)nib;

@property (nonatomic, weak) IBOutlet ZNGLabelGridView * labelGrid;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UILabel *lastMessage;
@property (weak, nonatomic) IBOutlet UIImageView * unconfirmedCircle;

@end
