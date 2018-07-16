//
//  ZNGCalendarEvent.h
//  ZingleSDK
//
//  Created by Jason Neel on 7/6/18.
//

#import <Mantle/Mantle.h>

@interface ZNGCalendarEvent : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong, nullable) NSString * calendarEventId;
@property (nonatomic, strong, nullable) NSString * eventTypeId;
@property (nonatomic, strong, nullable) NSString * title;
@property (nonatomic, strong, nullable) NSString * eventDescription;
@property (nonatomic, strong, nullable) NSDate * createdAt;
@property (nonatomic, strong, nullable) NSDate * updatedAt;
@property (nonatomic, strong, nullable) NSDate * startsAt;
@property (nonatomic, strong, nullable) NSDate * endsAt;

/**
 *  Creates and returns a date formatter to be used to display events' days of the month.
 */
+ (NSDateFormatter * _Nonnull) eventDayFormatter;

/**
 *  Creates and returns a date formatter to be used to display events' three letter months.
 */
+ (NSDateFormatter * _Nonnull) eventMonthFormatter;

/**
 *  Creates and returns a date formatter to be used to display events' times.
 */
+ (NSDateFormatter * _Nonnull) eventTimeFormatter;

/**
 *  Creates and returns a date formatter to be used to display month, day, and time.
 *  e.g. "May 8 1:00 AM"
 *
 *  Generally used to display ends_at that occurs on different day than starts_at,
 *  e.g. the latter half of "11:00 PM - May 8 1:00 AM" for a two hour event on May 7 11:00 PM.
 */
+ (NSDateFormatter * _Nonnull) eventMonthDayTimeFormatter;

/**
 *  Sort descriptors to chronologically sort events
 */
+ (NSArray<NSSortDescriptor *> * _Nonnull) sortDescriptors;

/**
 *  Returns YES if the starts_at and ends_at dates occur on the same calendar day.
 */
- (BOOL) singleDay;

@end
