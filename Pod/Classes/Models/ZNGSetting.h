//
//  ZNGSetting.h
//  Pods
//
//  Created by Jason Neel on 12/1/16.
//
//

#import <Mantle/Mantle.h>

@class ZNGSettingsField;

@interface ZNGSetting : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong, nullable) NSString * value;
@property (nonatomic, strong, nullable) NSString * settingsFieldOptionId;
@property (nonatomic, strong, nullable) ZNGSettingsField * settingsField;

@end
