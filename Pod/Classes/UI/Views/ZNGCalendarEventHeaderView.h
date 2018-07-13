//
//  ZNGCalendarEventHeaderView.h
//  ZingleSDK
//
//  Created by Jason Neel on 7/13/18.
//

#import <UIKit/UIKit.h>

@interface ZNGCalendarEventHeaderView : UITableViewHeaderFooterView

@property (nonatomic, strong, nullable) IBOutlet UIView * todayBottomBorder;
@property (nonatomic, strong, nullable) IBOutlet UILabel * dateLabel;
@property (nonatomic, strong, nullable) IBOutlet UILabel * todayLabel;

@end
