//
//  ZNGSettingsField.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>

@class ZNGFieldOption;

@interface ZNGSettingsField : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* settingId;
@property(nonatomic, strong) NSString * code;
@property(nonatomic, strong) NSString* displayName;
@property(nonatomic, strong) NSString* dataType;
@property(nonatomic, strong) NSArray<ZNGFieldOption *> * options;

@end
