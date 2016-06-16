//
//  ZNGTableViewCell.h
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGContact.h"

@class ZingleAccountSession;

@class ZNGTableViewCell;
/**
 *  The `ZNGTableViewCellDelegate` protocol defines methods that allow you to manage
 *  additional interactions within the table view cell.
 */
@protocol ZNGTableViewCellDelegate <NSObject>

@required

@end

@interface ZNGTableViewCell : UITableViewCell

+ (NSString *)cellReuseIdentifier;

+ (UINib *)nib;

- (void)configureCellWithContact:(ZNGContact *)contact withServiceId:(NSString *)serviceId;

/**
 *  The object that acts as the delegate for the cell.
 */
@property (weak, nonatomic) id<ZNGTableViewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UICollectionView *labelCollectionView;

@property (nonatomic, weak) ZingleAccountSession * session;

@end
