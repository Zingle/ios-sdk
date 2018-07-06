//
//  ZNGCalendarEvent.m
//  ZingleSDK
//
//  Created by Jason Neel on 7/6/18.
//

#import "ZNGCalendarEvent.h"
#import "ZingleValueTransformers.h"

@implementation ZNGCalendarEvent

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(calendarEventId)): @"id",
             NSStringFromSelector(@selector(eventTypeId)): @"type_id",
             NSStringFromSelector(@selector(title)): @"title",
             NSStringFromSelector(@selector(eventDescription)): @"description",
             NSStringFromSelector(@selector(createdAt)): @"created_at",
             NSStringFromSelector(@selector(updatedAt)): @"updated_at",
             NSStringFromSelector(@selector(startsAt)): @"starts_at",
             NSStringFromSelector(@selector(endsAt)): @"ends_at",
             };
}

+ (NSValueTransformer*)createdAtJSONTransformer
{
    return [ZingleValueTransformers millisecondDateValueTransformer];
}

+ (NSValueTransformer*)updatedAtJSONTransformer
{
    return [ZingleValueTransformers millisecondDateValueTransformer];
}

+ (NSValueTransformer*)startsAtJSONTransformer
{
    return [ZingleValueTransformers millisecondDateValueTransformer];
}

+ (NSValueTransformer*)endsAtJSONTransformer
{
    return [ZingleValueTransformers millisecondDateValueTransformer];
}

@end
