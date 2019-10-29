//
//  ZNGContactEventTableViewCell.h
//  ZingleSDK
//
//  Created by Jason Neel on 7/6/18.
//

#import <UIKit/UIKit.h>

@interface ZNGContactEventTableViewCell : UITableViewCell

@property (nonatomic, strong, nullable) IBOutlet NSLayoutConstraint * leftnessConstraint;

@property (nonatomic, strong, nullable) IBOutlet UIView * roundedBackgroundView;
@property (nonatomic, strong, nullable) IBOutlet UIView * darkeningOverlay;
@property (nonatomic, strong, nullable) IBOutlet UIView * dividerLine;

/**
 *  How much the event bubble should be darkened (perhaps to indicate a past event).  Defaults to 0.0.
 */
@property (nonatomic, assign) CGFloat darkenAmount;

@property (nonatomic, strong, nullable) IBOutlet UILabel * monthLabel;
@property (nonatomic, strong, nullable) IBOutlet UILabel * dayLabel;
@property (nonatomic, strong, nullable) IBOutlet UILabel * eventNameLabel;
@property (nonatomic, strong, nullable) IBOutlet UILabel * timeLabel;

@property (nonatomic, readonly, nullable) NSArray<UILabel *> * textLabels;

@end
