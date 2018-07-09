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
    
    self.roundedBackgroundView.layer.cornerRadius = 5.0;
    self.roundedBackgroundView.layer.borderWidth = 1.0;
}

@end
