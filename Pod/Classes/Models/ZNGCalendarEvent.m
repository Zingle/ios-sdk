//
//  ZNGCalendarEvent.m
//  ZingleSDK
//
//  Created by Jason Neel on 7/6/18.
//

#import "ZNGCalendarEvent.h"
#import "ZingleValueTransformers.h"

@import SBObjectiveCWrapper;

@implementation ZNGCalendarEvent

- (BOOL) isEqual:(ZNGCalendarEvent *)other
{
    if (![other isKindOfClass:[ZNGCalendarEvent class]]) {
        return NO;
    }
    
    return [self.calendarEventId isEqualToString:other.calendarEventId];
}

- (NSUInteger) hash
{
    return [self.calendarEventId hash];
}

- (BOOL) singleDay
{
    if ((self.startsAt == nil) || (self.endsAt == nil)) {
        SBLogWarning(@"%@ event is missing either start (%@) or end date (%@)", self.calendarEventId, self.startsAt, self.endsAt);
        return NO;
    }
    
    NSCalendar * calendar = [NSCalendar currentCalendar];
    NSCalendarUnit calendarUnit = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
    NSDateComponents * startComponents = [calendar components:calendarUnit fromDate:self.startsAt];
    NSDateComponents * endComponents = [calendar components:calendarUnit fromDate:self.endsAt];
    
    return ((startComponents.day == endComponents.day) && (startComponents.month == endComponents.month) && (startComponents.year == endComponents.year));
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

+ (NSDateFormatter * _Nonnull) eventMonthDayTimeFormatter
{
    NSDateFormatter * eventMonthDayTimeFormatter = [[NSDateFormatter alloc] init];
    eventMonthDayTimeFormatter.dateFormat = @"MMM d h:m a";
    return eventMonthDayTimeFormatter;
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

- (BOOL) isPast
{
    if (self.endsAt == nil) {
        return NO;
    }
    
    return ([self.endsAt timeIntervalSinceNow] <= 0.0);
}

@end
