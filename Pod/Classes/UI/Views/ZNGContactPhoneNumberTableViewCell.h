//
//  ZNGContactPhoneNumberTableViewCell.h
//  Pods
//
//  Created by Jason Neel on 8/24/16.
//
//

#import <UIKit/UIKit.h>

@class ZNGChannel;
@class ZNGService;

@interface ZNGContactPhoneNumberTableViewCell : UITableViewCell <UITextFieldDelegate>

/**
 *  If the service property is not set, channels will not be formatted correctly.
 */
@property (nonatomic, strong) ZNGService * service;

@property (nonatomic, copy) ZNGChannel * channel;

@property (nonatomic, strong) IBOutlet UITextField * textField;

@end
