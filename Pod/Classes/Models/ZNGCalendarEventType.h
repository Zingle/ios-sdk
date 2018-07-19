//
//  ZNGCalendarEventType.h
//  ZingleSDK
//
//  Created by Jason Neel on 7/6/18.
//

#import <Mantle/Mantle.h>

@interface ZNGCalendarEventType : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong, nullable) NSString * eventTypeId;
@property (nonatomic, strong, nullable) NSString * name;
@property (nonatomic, strong, nullable) NSString * eventTypeDescription;
@property (nonatomic, assign) BOOL isDefault;
@property (nonatomic, strong, nullable) NSString * backgroundColor;
@property (nonatomic, strong, nullable) NSString * textColor;

@end
