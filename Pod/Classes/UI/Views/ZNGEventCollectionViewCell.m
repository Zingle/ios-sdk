//
//  ZNGEventCollectionViewCell.m
//  Pods
//
//  Created by Jason Neel on 7/13/16.
//
//

#import "ZNGEventCollectionViewCell.h"

@implementation ZNGEventCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.textLabel.clipsToBounds = YES; // clips to bounds must be set for the below corner radius to work
    self.textLabel.layer.cornerRadius = 6.0;
}

@end
