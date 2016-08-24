//
//  ZNGContactChannelTableViewCell.h
//  Pods
//
//  Created by Jason Neel on 8/24/16.
//
//

#import <UIKit/UIKit.h>

@class JVFloatLabeledTextField;
@class ZNGChannel;

@interface ZNGContactChannelTableViewCell : UITableViewCell <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet JVFloatLabeledTextField * textField;

@property (nonatomic, strong) ZNGChannel * channel;

@end
