//
//  ZNGContactCustomFieldTableViewCell.m
//  Pods
//
//  Created by Jason Neel on 8/23/16.
//
//

#import "ZNGContactCustomFieldTableViewCell.h"
#import "ZNGContactFieldValue.h"
#import "ZNGFieldOption.h"
#import "UIColor+ZingleSDK.h"

@import JVFloatLabeledTextField;
@import SBObjectiveCWrapper;

static NSString * const CellIdSpinnySelect = @"fieldPicker";
static NSString * const CellIdFreeText = @"fieldText";
static NSString * const CellIdDateOrTime = @"fieldDateOrTime";
static NSString * const CellIdIos14DateOrTime = @"fieldDateOrTime_iOS14";

@implementation ZNGContactCustomFieldTableViewCell
{
    UIColor * lockedBackgroundColor;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGContactCustomFieldTableViewCell class]];
    lockedBackgroundColor = [UIColor colorNamed:@"ZNGDisabledBackground" inBundle:bundle compatibleWithTraitCollection:nil];
}

+ (NSString * _Nonnull) cellReuseIdForCustomFieldValue:(ZNGContactFieldValue * _Nonnull)fieldValue
{
    NSString * type = fieldValue.customField.dataType;
    
    NSArray <NSString *> * spinnyTypes = @[
        ZNGContactFieldDataTypeBool,
        ZNGContactFieldDataTypeSingleSelect,
    ];
    
    NSArray <NSString *> * dateOrTimeTypes = @[
        ZNGContactFieldDataTypeDate,
        ZNGContactFieldDataTypeTime,
        ZNGContactFieldDataTypeDateTime,
        ZNGContactFieldDataTypeAnniversary,
    ];
    
    if ([spinnyTypes containsObject:type]) {
        return CellIdSpinnySelect;
    } else if ([dateOrTimeTypes containsObject:type]) {
        // TODO: Implement in-line pickers
//        if (@available(iOS 14.0, *)) {
//            return CellIdIos14DateOrTime;
//        }
        
        return CellIdDateOrTime;
    }
    
    return CellIdFreeText;
}

- (void) setEditingLocked:(BOOL)editingLocked
{
    [super setEditingLocked:editingLocked];
    [self configureInput];
    [self updateDisplay];
}

- (void) setCustomFieldValue:(ZNGContactFieldValue *)customFieldValue
{
    SBLogVerbose(@"%@ custom field type set to %@ (type %@), was %@", [self class], customFieldValue.customField.displayName, customFieldValue.customField.dataType, _customFieldValue.customField.displayName);
    
    _customFieldValue = customFieldValue;
    
    [self configureInput];
    [self updateDisplay];
}

- (void) updateDisplay
{
    // Abstract, empty implementation
}

- (void) configureInput
{
    // Abstract, empty implementation
}

- (void) applyInProgressChanges
{
    // Empty, abstract implementation
}

@end
