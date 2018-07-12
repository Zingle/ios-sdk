//
//  ZNGCalendarEvent.m
//  ZingleSDK
//
//  Created by Jason Neel on 7/6/18.
//

#import "ZNGCalendarEvent.h"
#import "ZingleValueTransformers.h"

@implementation ZNGCalendarEvent

- (BOOL) isEqual:(ZNGCalendarEvent *)other
{
    if (![other isKindOfClass:[ZNGCalendarEvent class]]) {
        return NO;
    }
    
    return [self.calendarEventId isEqualToString:other.calendarEventId];
}

+ (NSDateFormatter *) eventDayFormatter
{
    NSDateFormatter * eventDayFormatter = [[NSDateFormatter alloc] init];
    eventDayFormatter.dateFormat = @"d";
    return eventDayFormatter;
}

+ (NSDateFormatter *) eventMonthFormatter
{
    NSDateFormatter * eventMonthFormatter = [[NSDateFormatter alloc] init];
    eventMonthFormatter.dateFormat = @"MMM";
    return eventMonthFormatter;
}

+ (NSDateFormatter *) eventTimeFormatter
{
    NSDateFormatter * eventTimeFormatter = [[NSDateFormatter alloc] init];
    eventTimeFormatter.dateStyle = NSDateFormatterNoStyle;
    eventTimeFormatter.timeStyle = NSDateFormatterShortStyle;
    return eventTimeFormatter;
}

- (NSUInteger) hash
{
    return [self.calendarEventId hash];
}

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

+ (NSArray<NSSortDescriptor *> * _Nonnull) sortDescriptors
{
    NSSortDescriptor * startTime = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(startsAt)) ascending:YES];
    NSSortDescriptor * endTime = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(endsAt)) ascending:YES];
    return @[startTime, endTime];
}

@end
