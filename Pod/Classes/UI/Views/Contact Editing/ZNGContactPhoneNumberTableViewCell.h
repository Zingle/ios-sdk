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
- (void) userClickedPhoneNumberTypeButtonOnCell:(ZNGContactPhoneNumberTableViewCell *)cell;

@end


@interface ZNGContactPhoneNumberTableViewCell : ZNGContactEditTableViewCell <UITextFieldDelegate>

/**
 *  If the service property is not set, channels will not be formatted correctly.
 */
@property (nonatomic, strong) ZNGService * service;

@property (nonatomic, strong) ZNGChannel * channel;

@property (nonatomic, strong) IBOutlet UITextField * textField;
@property (nonatomic, strong) IBOutlet UIButton * displayNameButton;

/**
 *  One of HOME, BUSINESS, MOBILE.  Stored/retrieved in all upper case but displayed in all lower case.
 */
@property (nonatomic, copy) NSString * displayName;

@property (nonatomic, weak) id <ZNGContactPhoneNumberTableCellDelegate> delegate;

@end
