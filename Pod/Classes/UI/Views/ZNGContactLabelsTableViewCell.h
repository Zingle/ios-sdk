//
//  ZNGContactLabelsTableViewCell.h
//  Pods
//
//  Created by Jason Neel on 8/24/16.
//
//

#import <UIKit/UIKit.h>

extern NSString * const ZNGContactLabelsCollectionViewCellReuseIdentifier;

@interface ZNGContactLabelsTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UICollectionView * collectionView;

@end
