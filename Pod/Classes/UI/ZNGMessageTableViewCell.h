//
//  ZNGMessageTableViewCell.h
//  Pods
//
//  Created by Ryan Farley on 2/22/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGMessage.h"

@interface ZNGMessageTableViewCell : UITableViewCell

- (void)setMessageModel:(ZNGMessage*)messageModel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oUserInfoBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oUserInfoMiddleConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oUserInfoTopConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oAdjustableEdgeConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oFixedEdgeConstraint;
@property (strong, nonatomic) NSDateFormatter *timestampDateFormatter;

@property (weak, nonatomic) IBOutlet UITextView *oTextView;

@property (weak, nonatomic) IBOutlet UIView *oImageContainerView;
@property (weak, nonatomic) IBOutlet UILabel *oInitialsLabel;
@property (weak, nonatomic) IBOutlet UIImageView *oProfileImageView;
@property (weak, nonatomic) IBOutlet UILabel *oTimeStampLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oBubbleMinWidth;

@property (strong, nonatomic)UIColor* bubbleColor;
@property (strong, nonatomic)UIColor* textColor;

@end
