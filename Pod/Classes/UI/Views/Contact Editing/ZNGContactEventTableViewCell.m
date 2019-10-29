//
//  ZNGContactEventTableViewCell.m
//  ZingleSDK
//
//  Created by Jason Neel on 7/6/18.
//

#import "ZNGContactEventTableViewCell.h"

@implementation ZNGContactEventTableViewCell

- (void) awakeFromNib
{
    [super awakeFromNib];
        
    self.leftnessConstraint.constant = 46.0;
    self.roundedBackgroundView.layer.cornerRadius = 3.0;
    self.roundedBackgroundView.layer.borderWidth = 1.0;
    
    self.darkeningOverlay.layer.cornerRadius = self.roundedBackgroundView.layer.cornerRadius;
    self.darkeningOverlay.alpha = self.darkenAmount;
}

- (void) setDarkenAmount:(CGFloat)darkenAmount
{
    _darkenAmount = darkenAmount;
    self.darkeningOverlay.alpha = darkenAmount;
}

- (NSArray<UILabel *> *) textLabels
{
    NSMutableArray<UILabel *> * labels = [[NSMutableArray alloc] initWithCapacity:4];
    
    if (_monthLabel != nil) {
        [labels addObject:_monthLabel];
    }
    
    if (_dayLabel != nil) {
        [labels addObject:_dayLabel];
    }
    
    if (_eventNameLabel != nil) {
        [labels addObject:_eventNameLabel];
    }
    
    if (_timeLabel != nil) {
        [labels addObject:_timeLabel];
    }
    
    return labels;
}

@end
