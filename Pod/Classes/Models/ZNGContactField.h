//
//  ZNGContactField.h
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import <Mantle/Mantle.h>

@class ZNGFieldOption;

extern NSString * const ZNGContactFieldDataTypeString;
extern NSString * const ZNGContactFieldDataTypeNumber;
extern NSString * const ZNGContactFieldDataTypeBool;
extern NSString * const ZNGContactFieldDataTypeDate;
extern NSString * const ZNGContactFieldDataTypeAnniversary;
extern NSString * const ZNGContactFieldDataTypeTime;
extern NSString * const ZNGContactFieldDataTypeDateTime;
extern NSString * const ZNGContactFieldDataTypeSingleSelect;

@interface ZNGContactField : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* contactFieldId;
@property(nonatomic, strong) NSString* displayName;
@property(nonatomic, strong) NSString * code;
@property(nonatomic, strong) NSString* dataType;
@property(nonatomic) BOOL isGlobal;
@property(nonatomic, strong) NSArray<ZNGFieldOption *> * options;// Array of ZNGFieldOption
@property(nonatomic, strong) NSString * replacementVariable;    // The value to be put within { } to be magically replaced by the server.

/**
 *  Returns YES if autocapitalization should be on for every word
 */
- (BOOL) shouldCapitalizeEveryWord;

@end
