//
//  ZNGContactChannelTableViewCell.h
//  Pods
//
//  Created by Jason Neel on 8/24/16.
//
//

#import "ZNGContactEditTableViewCell.h"

@class JVFloatLabeledTextField;
@class ZNGChannel;

@interface ZNGContactChannelTableViewCell : ZNGContactEditTableViewCell <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet JVFloatLabeledTextField * textField;

@property (nonatomic, strong) ZNGChannel * channel;

@end
