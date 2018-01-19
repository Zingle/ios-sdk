//
//  ZNGAssignUserTableViewCell.m
//  ZingleSDK
//
//  Created by Jason Neel on 1/11/18.
//

#import "ZNGAssignUserTableViewCell.h"

@implementation ZNGAssignUserTableViewCell

- (void) prepareForReuse
{
    [super prepareForReuse];
    
    for (UIView * view in [self.avatarContainer.subviews copy]) {
        [view removeFromSuperview];
    }
}

@end
