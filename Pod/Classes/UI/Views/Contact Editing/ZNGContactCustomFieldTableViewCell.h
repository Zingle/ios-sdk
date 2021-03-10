//
//  ZNGContactCustomFieldTableViewCell.h
//  Pods
//
//  Created by Jason Neel on 8/23/16.
//
//

#import "ZNGContactEditTableViewCell.h"
@class JVFloatLabeledTextField;
@class ZNGContactFieldValue;

@interface ZNGContactCustomFieldTableViewCell : ZNGContactEditTableViewCell

+ (NSString * _Nonnull) cellReuseIdForCustomFieldValue:(ZNGContactFieldValue * _Nonnull)fieldValue;

@property (nonatomic, strong, nullable) ZNGContactFieldValue * customFieldValue;

/**
 *  Called whenever the custom field value object is set (NOT when the text `.value` is changed)
 */
- (void) configureInput;

/**
 *  Updates UI to reflect current value of `self.customFieldValue.value`
 */
- (void) updateDisplay;

@end
