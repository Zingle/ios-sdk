//
//  ZNGContactPhoneNumberTableViewCell.h
//  Pods
//
//  Created by Jason Neel on 8/24/16.
//
//

#import "ZNGContactEditTableViewCell.h"

@class ZNGChannel;
@class ZNGService;
@class ZNGContactPhoneNumberTableViewCell;

@protocol ZNGContactPhoneNumberTableCellDelegate <NSObject>

@optional
- (void) userClickedDeleteOnPhoneNumberTableCell:(ZNGContactPhoneNumberTableViewCell *)cell;

@end


@interface ZNGContactPhoneNumberTableViewCell : ZNGContactEditTableViewCell <UITextFieldDelegate>

/**
 *  If the service property is not set, channels will not be formatted correctly.
 */
@property (nonatomic, strong) ZNGService * service;

@property (nonatomic, strong) ZNGChannel * channel;

@property (nonatomic, strong) IBOutlet UITextField * textField;

@property (nonatomic, weak) id <ZNGContactPhoneNumberTableCellDelegate> delegate;

@end
