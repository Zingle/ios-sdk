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

@protocol ZNGContactFieldEditDelegate <NSObject>
- (void) contactFieldCell:(ZNGContactEditTableViewCell * _Nonnull)cell valueChanged:(ZNGContactFieldValue * _Nonnull)contactFieldValue;
@end

@interface ZNGContactCustomFieldTableViewCell : ZNGContactEditTableViewCell

+ (NSString * _Nonnull) cellReuseIdForCustomFieldValue:(ZNGContactFieldValue * _Nonnull)fieldValue;

@property (nonatomic, weak, nullable) id <ZNGContactFieldEditDelegate> delegate;
@property (nonatomic, strong, nullable) ZNGContactFieldValue * customFieldValue;

/**
 *  Instructs the cell to write any in-progress (read: input is first responder) changes.
 */
- (void) applyInProgressChanges;

/**
 *  Called whenever the custom field value object is set (NOT when the text `.value` is changed)
 */
- (void) configureInput;

/**
 *  Updates UI to reflect current value of `self.customFieldValue.value`
 */
- (void) updateDisplay;

@end
