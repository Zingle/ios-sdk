//
//  ZNGContactTextFieldTableViewCell.h
//  
//
//  Created by Jason Neel on 11/23/20.
//

#import <ZingleSDK/ZingleSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZNGContactTextFieldTableViewCell : ZNGContactCustomFieldTableViewCell

@property (nonatomic, strong) IBOutlet JVFloatLabeledTextField * textField;

@end

NS_ASSUME_NONNULL_END
