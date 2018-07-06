//
//  ZNGCalendarEventType.m
//  ZingleSDK
//
//  Created by Jason Neel on 7/6/18.
//

#import "ZNGCalendarEventType.h"

@implementation ZNGCalendarEventType

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(backgroundColor)): @"backgroundColor",
             NSStringFromSelector(@selector(isDefault)): @"isDefault",
             NSStringFromSelector(@selector(name)): @"name",
             NSStringFromSelector(@selector(eventTypeDescription)): @"description",
             NSStringFromSelector(@selector(eventTypeId)): @"uuid",
             NSStringFromSelector(@selector(textColor)): @"textColor",
             };
}

@end
