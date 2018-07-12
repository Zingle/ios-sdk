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

+ (NSArray<NSSortDescriptor *> * _Nonnull) sortDescriptors;

@end
