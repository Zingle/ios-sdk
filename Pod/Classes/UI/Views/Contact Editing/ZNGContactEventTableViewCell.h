//
//  ZNGContactEventTableViewCell.h
//  ZingleSDK
//
//  Created by Jason Neel on 7/6/18.
//

#import <UIKit/UIKit.h>

@interface ZNGContactEventTableViewCell : UITableViewCell

@property (nonatomic, strong, nullable) IBOutlet UIView * roundedBackgroundView;
@property (nonatomic, strong, nullable) IBOutlet UIView * dividerLine;

@property (nonatomic, strong, nullable) IBOutlet UILabel * monthLabel;
@property (nonatomic, strong, nullable) IBOutlet UILabel * dayLabel;
@property (nonatomic, strong, nullable) IBOutlet UILabel * eventNameLabel;
@property (nonatomic, strong, nullable) IBOutlet UILabel * timeLabel;

@property (nonatomic, readonly, nullable) NSArray<UILabel *> * textLabels;

@end
