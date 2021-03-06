//
//  ZNGCalendarEventHeaderView.m
//  ZingleSDK
//
//  Created by Jason Neel on 7/13/18.
//

#import "ZNGCalendarEventHeaderView.h"
#import "UIColor+ZingleSDK.h"

@implementation ZNGCalendarEventHeaderView

- (void) prepareForReuse
{
    [super prepareForReuse];
    self.todayBottomBorder.hidden = YES;
    self.todayLabel.hidden = YES;
    self.dateLabel.textColor = [UIColor colorFromHexString:@"#6B6B6B"];
}

@end
