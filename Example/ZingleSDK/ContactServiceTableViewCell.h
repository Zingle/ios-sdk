//
//  ContactServiceTableViewCell.h
//  ZingleSDK
//
//  Created by Jason Neel on 6/17/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactServiceTableViewCell : UITableViewCell

@property (nonatomic, strong, nullable) IBOutlet UILabel * serviceLabel;
@property (nonatomic, strong, nullable) IBOutlet UILabel * messageLabel;
@property (nonatomic, strong, nullable) IBOutlet UILabel * timestampLabel;

@end
